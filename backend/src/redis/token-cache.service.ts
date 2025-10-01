import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cache } from 'cache-manager';
import { createClient } from 'redis';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class TokenCacheService implements OnModuleInit {
  private readonly logger = new Logger(TokenCacheService.name);
  private redisClient;

  constructor(
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
    private configService: ConfigService,
  ) {}

  async onModuleInit() {
    // In test environments, avoid connecting to external Redis
    if (process.env.NODE_ENV === 'test' || process.env.USE_IN_MEMORY_CACHE === '1') {
      this.logger.log('Using in-memory token cache (test mode)');
      const mem = new Map<string, string>();
      this.redisClient = {
        async set(key: string, value: string, opts?: any) {
          mem.set(key, value);
        },
        async get(key: string) {
          return mem.get(key) ?? null;
        },
        async del(key: string) {
          mem.delete(key);
        },
        async *scanIterator(_: any) {
          for (const key of mem.keys()) {
            yield key;
          }
        },
      } as any;
      return;
    }

    this.redisClient = createClient({
      url: `redis://${this.configService.get('REDIS_HOST', 'localhost')}:${this.configService.get('REDIS_PORT', 6379)}`,
    });

    this.redisClient.on('error', (error) => {
      this.logger.error('Redis Client Error:', error);
    });

    this.redisClient.on('connect', () => {
      this.logger.log('Connected to Redis');
    });

    await this.redisClient.connect();
  }

  async storeRefreshToken(userId: string, refreshToken: string, ttl: number = 604800): Promise<void> {
    const key = `refresh_token:${refreshToken}`;
    this.logger.debug(`Attempting to store refresh token in Redis...`);
    this.logger.debug(`Key: ${key}`);
    this.logger.debug(`UserId: ${userId}`);
    this.logger.debug(`TTL: ${ttl} seconds`);
    
    try {
      await this.redisClient.set(key, userId, {
        EX: ttl
      });
      
      const stored = await this.redisClient.get(key);
      this.logger.debug(`Cache verification - Key exists: ${stored !== null}`);
      this.logger.debug(`Cache verification - Stored value: ${stored}`);
      
      if (stored === null) {
        throw new Error('Token was not stored in Redis');
      }
    } catch (error) {
      this.logger.error(`Failed to store refresh token: ${error.message}`);
      throw error;
    }
  }

  async getUserIdByRefreshToken(refreshToken: string): Promise<string | null> {
    const key = `refresh_token:${refreshToken}`;
    try {
      const result = await this.redisClient.get(key);
      this.logger.debug(`Retrieved value for ${key}: ${result}`);
      return result;
    } catch (error) {
      this.logger.error(`Failed to get refresh token: ${error.message}`);
      throw error;
    }
  }

  async removeRefreshToken(refreshToken: string): Promise<void> {
    const key = `refresh_token:${refreshToken}`;
    try {
      await this.redisClient.del(key);
      this.logger.debug(`Removed refresh token: ${refreshToken}`);
    } catch (error) {
      this.logger.error(`Failed to remove refresh token: ${error.message}`);
      throw error;
    }
  }

  async removeAllUserRefreshTokens(userId: string): Promise<void> {
    // Scan all refresh_token:* keys and delete those belonging to the user
    try {
      // Using node-redis v4 scanIterator for efficient key scanning
      const iter = this.redisClient.scanIterator({ MATCH: 'refresh_token:*', COUNT: 200 });
      for await (const key of iter) {
        try {
          const owner = await this.redisClient.get(key);
          if (owner === userId) {
            await this.redisClient.del(key);
          }
        } catch (innerErr) {
          this.logger.warn(`Failed processing key ${key}: ${innerErr?.message || innerErr}`);
        }
      }
    } catch (error) {
      this.logger.error(`Failed to remove all refresh tokens for user ${userId}: ${error.message}`);
      // Swallow to avoid blocking callers, but log for observability
    }
  }
}