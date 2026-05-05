import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Project, ProjectDocument } from './schemas/project.schema';
import { CreateProjectDto, UpdateProjectDto } from './dto/project.dto';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectModel(Project.name) private projectModel: Model<ProjectDocument>,
  ) {}

  async create(
    createProjectDto: CreateProjectDto,
    userId: string,
  ): Promise<ProjectDocument> {
    const project = new this.projectModel({
      ...createProjectDto,
      owner: new Types.ObjectId(userId),
      members: [new Types.ObjectId(userId)],
    });
    return (await project.save()).populate('owner members', '-password');
  }

  async findAll(userId: string): Promise<ProjectDocument[]> {
    return this.projectModel
      .find({
        $or: [
          { owner: new Types.ObjectId(userId) },
          { members: new Types.ObjectId(userId) },
        ],
      })
      .populate('owner members', '-password')
      .sort({ updatedAt: -1 })
      .exec();
  }

  async findById(id: string): Promise<ProjectDocument> {
    const project = await this.projectModel
      .findById(id)
      .populate('owner members', '-password')
      .exec();
    if (!project) {
      throw new NotFoundException('Project not found');
    }
    return project;
  }

  async update(
    id: string,
    updateProjectDto: UpdateProjectDto,
    userId: string,
  ): Promise<ProjectDocument> {
    const project = await this.findById(id);

    if (project.owner._id.toString() !== userId) {
      throw new ForbiddenException('Only the project owner can update');
    }

    const updated = await this.projectModel
      .findByIdAndUpdate(id, updateProjectDto, { new: true })
      .populate('owner members', '-password')
      .exec();

    return updated!;
  }

  async delete(id: string, userId: string): Promise<void> {
    const project = await this.findById(id);

    if (project.owner._id.toString() !== userId) {
      throw new ForbiddenException('Only the project owner can delete');
    }

    await this.projectModel.findByIdAndDelete(id).exec();
  }

  async addMember(
    projectId: string,
    memberId: string,
    userId: string,
  ): Promise<ProjectDocument> {
    const project = await this.findById(projectId);

    if (project.owner._id.toString() !== userId) {
      throw new ForbiddenException('Only the project owner can add members');
    }

    const updated = await this.projectModel
      .findByIdAndUpdate(
        projectId,
        { $addToSet: { members: new Types.ObjectId(memberId) } },
        { new: true },
      )
      .populate('owner members', '-password')
      .exec();

    return updated!;
  }

  async removeMember(
    projectId: string,
    memberId: string,
    userId: string,
  ): Promise<ProjectDocument> {
    const project = await this.findById(projectId);

    if (project.owner._id.toString() !== userId) {
      throw new ForbiddenException('Only the project owner can remove members');
    }

    const updated = await this.projectModel
      .findByIdAndUpdate(
        projectId,
        { $pull: { members: new Types.ObjectId(memberId) } },
        { new: true },
      )
      .populate('owner members', '-password')
      .exec();

    return updated!;
  }
}
