import { CacheModule } from '@nestjs/cache-manager';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TokenCacheService } from './token-cache.service';
import { createClient } from 'redis';

@Module({
  imports: [
    CacheModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      isGlobal: true,
      useFactory: async (configService: ConfigService) => {
        const client = createClient({
          url: `redis://${configService.get('REDIS_HOST', 'localhost')}:${configService.get('REDIS_PORT', 6379)}`,
        });

        await client.connect();

        return {
          store: client,
          ttl: 60 * 60 * 24 * 7, // 7 days default TTL
          isGlobal: true,
        };

      },
    }),
  ],
  providers: [TokenCacheService],
  exports: [CacheModule, TokenCacheService],
})
export class RedisCacheModule {}