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
    // This would require implementing a reverse lookup or pattern search in Redis
    // For now, we'll just handle single token removal
    this.logger.warn('removeAllUserRefreshTokens not implemented yet');
  }
}