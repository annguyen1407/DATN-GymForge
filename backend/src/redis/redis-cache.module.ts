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
        // In test environments, avoid connecting to external Redis and use in-memory cache
        if (process.env.NODE_ENV === 'test' || process.env.USE_IN_MEMORY_CACHE === '1') {
          return {
            ttl: 60 * 60 * 24, // 1 day default TTL
            isGlobal: true,
          } as any;
        }

        const client = createClient({
          url: `redis://${configService.get('REDIS_HOST', 'localhost')}:${configService.get('REDIS_PORT', 6379)}`,
        });

        await client.connect();

        return {
          store: client,
          ttl: 60 * 60 * 24 * 7, // 7 days default TTL
          isGlobal: true,
        } as any;
      },
    }),
  ],
  providers: [TokenCacheService],
  exports: [CacheModule, TokenCacheService],
})
export class RedisCacheModule {}