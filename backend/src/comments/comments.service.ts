import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Comment } from './comment.entity';
import { CreateCommentDto } from './dto/create-comment.dto';
import { User } from '../users/user.entity';

export interface CommentNode extends Comment {
  replies: CommentNode[];
}

@Injectable()
export class CommentsService {
  constructor(
    @InjectRepository(Comment)
    private readonly commentsRepository: Repository<Comment>,
  ) {}

  async findForRecipe(recipeId: string): Promise<CommentNode[]> {
    const all = await this.commentsRepository.find({
      where: { recipeId },
      order: { createdAt: 'ASC' },
    });
    return this.buildTree(all, null);
  }

  private buildTree(all: Comment[], parentId: string | null): CommentNode[] {
    return all
      .filter((c) => c.parentId === parentId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .map((c) => ({ ...c, replies: this.buildTree(all, c.id) }));
  }

  async create(recipeId: string, dto: CreateCommentDto, user: User): Promise<Comment> {
    if (dto.parentId) {
      const parent = await this.commentsRepository.findOne({ where: { id: dto.parentId } });
      if (!parent) {
        throw new NotFoundException('ไม่พบคอมเมนต์ต้นทาง');
      }
    }

    return this.commentsRepository.save(
      this.commentsRepository.create({
        recipeId,
        userId: user.id,
        userName: user.name,
        content: dto.content,
        parentId: dto.parentId ?? null,
        mentions: dto.mentions ?? [],
        imageUrl: dto.imageUrl ?? null,
      }),
    );
  }

  async remove(id: string, user: User): Promise<void> {
    const comment = await this.commentsRepository.findOne({ where: { id } });
    if (!comment) {
      throw new NotFoundException('ไม่พบคอมเมนต์นี้');
    }
    if (comment.userId !== user.id) {
      throw new ForbiddenException('ลบได้เฉพาะคอมเมนต์ของคุณเอง');
    }

    const idsToDelete = await this.collectDescendantIds(comment.recipeId, [id]);
    await this.commentsRepository.delete({ id: In(idsToDelete) });
  }

  private async collectDescendantIds(recipeId: string, rootIds: string[]): Promise<string[]> {
    const all = await this.commentsRepository.find({ where: { recipeId } });
    const result = new Set(rootIds);
    let changed = true;
    while (changed) {
      changed = false;
      for (const c of all) {
        if (c.parentId && result.has(c.parentId) && !result.has(c.id)) {
          result.add(c.id);
          changed = true;
        }
      }
    }
    return [...result];
  }
}
