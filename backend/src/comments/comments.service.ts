import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Comment } from './comment.entity';
import { CreateCommentDto } from './dto/create-comment.dto';
import { User } from '../users/user.entity';
import { RecipesService } from '../recipes/recipes.service';
import { removeUploadedFile } from '../common/image-upload';

export interface CommentNode extends Comment {
  replies: CommentNode[];
}

@Injectable()
export class CommentsService {
  constructor(
    @InjectRepository(Comment)
    private readonly commentsRepository: Repository<Comment>,
    private readonly recipesService: RecipesService,
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
    await this.recipesService.assertExists(recipeId);

    if (dto.parentId) {
      const parent = await this.commentsRepository.findOne({ where: { id: dto.parentId } });
      if (!parent) {
        throw new NotFoundException('ไม่พบคอมเมนต์ต้นทาง');
      }
      // A reply must live in the same thread, otherwise it would never show under its parent.
      if (parent.recipeId !== recipeId) {
        throw new BadRequestException('คอมเมนต์ต้นทางไม่ได้อยู่ในสูตรนี้');
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

  async setImage(id: string, imageUrl: string, user: User): Promise<Comment> {
    const comment = await this.commentsRepository.findOne({ where: { id } });
    if (!comment) {
      await removeUploadedFile(imageUrl);
      throw new NotFoundException('ไม่พบคอมเมนต์นี้');
    }
    if (comment.userId !== user.id) {
      await removeUploadedFile(imageUrl);
      throw new ForbiddenException('แนบรูปได้เฉพาะคอมเมนต์ของคุณเอง');
    }
    if (comment.imageUrl) {
      await removeUploadedFile(comment.imageUrl);
    }
    comment.imageUrl = imageUrl;
    return this.commentsRepository.save(comment);
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
