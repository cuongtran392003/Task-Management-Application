import { Injectable } from '@nestjs/common';
import { TasksService } from '../tasks/tasks.service';
import { ProjectsService } from '../projects/projects.service';

@Injectable()
export class DashboardService {
  constructor(
    private readonly tasksService: TasksService,
    private readonly projectsService: ProjectsService,
  ) {}

  async getStats(userId: string) {
    const taskStats = await this.tasksService.getStats(userId);
    const projects = await this.projectsService.findAll(userId);

    return {
      ...taskStats,
      totalProjects: projects.length,
    };
  }

  async getRecentTasks(userId: string) {
    return this.tasksService.getRecentTasks(userId);
  }
}
