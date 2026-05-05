import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Task, TaskDocument, TaskStatus } from './schemas/task.schema';
import { CreateTaskDto, UpdateTaskDto, QueryTaskDto } from './dto/task.dto';
import { FirebaseService } from '../firebase/firebase.service';

@Injectable()
export class TasksService {
  constructor(
    @InjectModel(Task.name) private taskModel: Model<TaskDocument>,
    private firebaseService: FirebaseService,
  ) {}

  async create(
    createTaskDto: CreateTaskDto,
    userId: string,
  ): Promise<TaskDocument> {
    const task = new this.taskModel({
      ...createTaskDto,
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

    if (saved.assignee && (saved.assignee as any).fcmTokens?.length > 0 && (saved.assignee as any)._id.toString() !== userId) {
      this.firebaseService.sendPushNotification(
        (saved.assignee as any).fcmTokens,
        'New Task Assigned',
        `You have been assigned to: ${saved.title}`,
        { taskId: saved.id },
      );
    }

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
}
