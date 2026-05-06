import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Task, TaskDocument, TaskStatus } from './schemas/task.schema';
import { CreateTaskDto, UpdateTaskDto, QueryTaskDto } from './dto/task.dto';
import { FirebaseService } from '../firebase/firebase.service';

@Injectable()
export class TasksService implements OnModuleInit {
  private readonly logger = new Logger(TasksService.name);
  constructor(
    @InjectModel(Task.name) private taskModel: Model<TaskDocument>,
    private firebaseService: FirebaseService,
  ) {}

  async onModuleInit() {
    await this.migrateLegacyTasks();
  }

  async create(
    createTaskDto: CreateTaskDto,
    userId: string,
  ): Promise<TaskDocument> {
    const reminderFields = this.buildReminderFields(
      createTaskDto.scheduledAt,
      createTaskDto.reminderBeforeMinutes,
    );
    const task = new this.taskModel({
      ...createTaskDto,
      ...reminderFields,
      project: new Types.ObjectId(createTaskDto.project),
      assignee: createTaskDto.assignee
        ? new Types.ObjectId(createTaskDto.assignee)
        : undefined,
      createdBy: new Types.ObjectId(userId),
    });
    const saved = await (await task.save()).populate([
      { path: 'assignee', select: '-password' },
      { path: 'createdBy', select: '-password' },
      { path: 'project' },
    ]);

    return saved;
  }

  async findAll(
    queryDto: QueryTaskDto,
    userId: string,
  ): Promise<{ tasks: TaskDocument[]; total: number; page: number; totalPages: number }> {
    const { status, priority, project, assignee, search, page = 1, limit = 20 } = queryDto;

    const filter: any = {};

    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (project) filter.project = new Types.ObjectId(project);
    if (assignee) filter.assignee = new Types.ObjectId(assignee);
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (page - 1) * limit;
    const total = await this.taskModel.countDocuments(filter).exec();

    const tasks = await this.taskModel
      .find(filter)
      .populate([
        { path: 'assignee', select: '-password' },
        { path: 'createdBy', select: '-password' },
        { path: 'project' },
      ])
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    return {
      tasks,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findById(id: string): Promise<TaskDocument> {
    const task = await this.taskModel
      .findById(id)
      .populate([
        { path: 'assignee', select: '-password' },
        { path: 'createdBy', select: '-password' },
        { path: 'project' },
      ])
      .exec();
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    return task;
  }

  async update(
    id: string,
    updateTaskDto: UpdateTaskDto,
  ): Promise<TaskDocument> {
    const updateData: any = { ...updateTaskDto };
    if (updateTaskDto.assignee) {
      updateData.assignee = new Types.ObjectId(updateTaskDto.assignee);
    }
    if (updateTaskDto.project) {
      updateData.project = new Types.ObjectId(updateTaskDto.project);
    }

    if (updateTaskDto.scheduledAt || updateTaskDto.reminderBeforeMinutes !== undefined) {
      const existingTask = await this.taskModel.findById(id).exec();
      if (!existingTask) {
        throw new NotFoundException('Task not found');
      }

      const scheduledAt = updateTaskDto.scheduledAt ?? existingTask.scheduledAt;
      const reminderBeforeMinutes =
        updateTaskDto.reminderBeforeMinutes ?? existingTask.reminderBeforeMinutes ?? 0;
      const reminderFields = this.buildReminderFields(scheduledAt, reminderBeforeMinutes);
      updateData.remindAt = reminderFields.remindAt;
      updateData.reminderBeforeMinutes = reminderFields.reminderBeforeMinutes;
      updateData.reminderSent = false;
    }

    const task = await this.taskModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .populate([
        { path: 'assignee', select: '-password' },
        { path: 'createdBy', select: '-password' },
        { path: 'project' },
      ])
      .exec();

    if (!task) {
      throw new NotFoundException('Task not found');
    }
    return task;
  }

  async updateStatus(id: string, status: string): Promise<TaskDocument> {
    const task = await this.taskModel
      .findByIdAndUpdate(id, { status }, { new: true })
      .populate([
        { path: 'assignee', select: '-password' },
        { path: 'createdBy', select: '-password' },
        { path: 'project' },
      ])
      .exec();

    if (!task) {
      throw new NotFoundException('Task not found');
    }
    return task;
  }

  async delete(id: string): Promise<void> {
    const result = await this.taskModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException('Task not found');
    }
  }

  async getTasksByProject(projectId: string): Promise<TaskDocument[]> {
    return this.taskModel
      .find({ project: new Types.ObjectId(projectId) })
      .populate([
        { path: 'assignee', select: '-password' },
        { path: 'createdBy', select: '-password' },
      ])
      .sort({ updatedAt: -1 })
      .exec();
  }

  async getStats(userId: string) {
    const userObjectId = new Types.ObjectId(userId);

    const userFilter = {
      $or: [{ assignee: userObjectId }, { createdBy: userObjectId }],
    } as any;

    const [totalTasks, todoTasks, inProgressTasks, doneTasks, urgentTasks] =
      await Promise.all([
        this.taskModel.countDocuments(userFilter),
        this.taskModel.countDocuments({
          ...userFilter,
          status: TaskStatus.TODO,
        } as any),
        this.taskModel.countDocuments({
          ...userFilter,
          status: TaskStatus.IN_PROGRESS,
        } as any),
        this.taskModel.countDocuments({
          ...userFilter,
          status: TaskStatus.DONE,
        } as any),
        this.taskModel.countDocuments({
          ...userFilter,
          priority: 'urgent',
          status: { $ne: TaskStatus.DONE },
        } as any),
      ]);

    return {
      totalTasks,
      todoTasks,
      inProgressTasks,
      doneTasks,
      urgentTasks,
      completionRate: totalTasks > 0 ? Math.round((doneTasks / totalTasks) * 100) : 0,
    };
  }

  async getRecentTasks(userId: string, limit = 10): Promise<TaskDocument[]> {
    const userObjectId = new Types.ObjectId(userId);
    return this.taskModel
      .find({
        $or: [{ assignee: userObjectId }, { createdBy: userObjectId }],
      } as any)
      .populate([
        { path: 'assignee', select: '-password' },
        { path: 'createdBy', select: '-password' },
        { path: 'project' },
      ])
      .sort({ updatedAt: -1 })
      .limit(limit)
      .exec();
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async handleCron() {
    const now = new Date();
    // Find tasks that are due, not done, and reminder not sent yet
    const dueTasks = await this.taskModel.find({
      status: { $ne: TaskStatus.DONE },
      reminderSent: { $ne: true },
      $or: [
        { $and: [{ remindAt: { $type: 'date' } }, { remindAt: { $lte: now } }] },
        { remindAt: { $exists: false }, scheduledAt: { $lte: now } },
        { remindAt: null, scheduledAt: { $lte: now } },
      ],
    }).populate('createdBy');

    for (const task of dueTasks) {
      if (!task.remindAt && task.scheduledAt) {
        const reminderFields = this.buildReminderFields(
          task.scheduledAt,
          task.reminderBeforeMinutes,
        );
        if (reminderFields.remindAt) {
          task.remindAt = reminderFields.remindAt;
        }
        task.reminderBeforeMinutes = reminderFields.reminderBeforeMinutes;
      }
      const creator = task.createdBy as any;
      if (creator && creator.fcmTokens?.length > 0) {
        await this.firebaseService.sendPushNotification(
          creator.fcmTokens,
          'Task Due Reminder',
          `Your task "${task.title}" is due today!`,
          { taskId: task.id },
        );
      }
      
      // Mark reminder as sent
      task.reminderSent = true;
      await task.save();
    }
  }

  private buildReminderFields(
    scheduledAt?: string | Date,
    reminderBeforeMinutes?: number,
  ): { remindAt?: Date; reminderBeforeMinutes: number } {
    const amount = Math.max(0, reminderBeforeMinutes ?? 0);
    if (!scheduledAt) {
      return { remindAt: undefined, reminderBeforeMinutes: amount };
    }
    const parsedScheduledAt =
      scheduledAt instanceof Date ? scheduledAt : new Date(scheduledAt);
    if (Number.isNaN(parsedScheduledAt.getTime())) {
      return { remindAt: undefined, reminderBeforeMinutes: amount };
    }
    return {
      remindAt: new Date(parsedScheduledAt.getTime() - amount * 60 * 1000),
      reminderBeforeMinutes: amount,
    };
  }

  private async migrateLegacyTasks(): Promise<void> {
    const legacyTasks = await this.taskModel
      .find({ dueDate: { $type: 'date' } })
      .select('_id dueDate scheduledAt reminderBeforeMinutes')
      .exec();

    if (legacyTasks.length === 0) {
      return;
    }

    const operations = legacyTasks.map((task) => {
      const scheduledAt = task.scheduledAt ?? (task as any).dueDate;
      const reminderBeforeMinutes = task.reminderBeforeMinutes ?? 0;
      const reminderFields = this.buildReminderFields(
        scheduledAt,
        reminderBeforeMinutes,
      );

      const setFields: Record<string, unknown> = {
        scheduledAt,
        reminderBeforeMinutes: reminderFields.reminderBeforeMinutes,
      };
      if (reminderFields.remindAt) {
        setFields.remindAt = reminderFields.remindAt;
      }

      return {
        updateOne: {
          filter: { _id: task._id },
          update: {
            $set: setFields,
            $unset: { dueDate: 1 },
          },
        },
      };
    });

    await this.taskModel.collection.bulkWrite(operations as any);
    this.logger.log(`Migrated ${legacyTasks.length} legacy task(s)`);
  }
}
