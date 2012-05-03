package org.wonkavision.redis.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.redis.WonkavisionRedisSettings
import org.wonkavision.redis.Redis

trait RedisRepositoryActor extends Actor {

	val redis = new Redis(context.system)
		
}