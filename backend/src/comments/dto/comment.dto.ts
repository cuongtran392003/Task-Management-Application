import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateCommentDto {
  @ApiProperty({ example: 'This task is almost done!' })
  @IsNotEmpty()
  @IsString()
  content: string;
}
