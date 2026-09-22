import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Favorite } from './favorite.entity';
import { FavoriteFolder } from './folder.entity';
import { FavoritesService } from './favorites.service';
import { FavoritesController } from './favorites.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Favorite, FavoriteFolder])],
  controllers: [FavoritesController],
  providers: [FavoritesService],
})
export class FavoritesModule {}
