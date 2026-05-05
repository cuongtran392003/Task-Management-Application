import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Comment, CommentDocument } from './schemas/comment.schema';
import { CreateCommentDto } from './dto/comment.dto';

@Injectable()
export class CommentsService {
  constructor(
    @InjectModel(Comment.name) private commentModel: Model<CommentDocument>,
  ) {}

  async create(
    taskId: string,
    createCommentDto: CreateCommentDto,
    userId: string,
  ): Promise<CommentDocument> {
    const comment = new this.commentModel({
      ...createCommentDto,
      task: new Types.ObjectId(taskId),
      author: new Types.ObjectId(userId),
    });
    return (await comment.save()).populate('author', '-password');
  }

  async findByTask(taskId: string): Promise<CommentDocument[]> {
    return this.commentModel
      .find({ task: new Types.ObjectId(taskId) })
      .populate('author', '-password')
      .sort({ createdAt: -1 })
      .exec();
  }

  async delete(id: string, userId: string): Promise<void> {
    const comment = await this.commentModel.findById(id).exec();
    if (!comment) {
      throw new NotFoundException('Comment not found');
    }
    if (comment.author.toString() !== userId) {
      throw new NotFoundException('You can only delete your own comments');
    }
    await this.commentModel.findByIdAndDelete(id).exec();
  }
}
