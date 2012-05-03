package org.wonkavision.server

import org.reflections.Reflections
import org.reflections.util.{ConfigurationBuilder,FilterBuilder,ClasspathHelper}
import org.reflections.scanners.SubTypesScanner
import scala.collection.JavaConversions._

import org.wonkavision.core.Cube

class AppLoader(namespaces : String*) {
	var ns = namespaces.toList
	val reflector = new Reflections(ns.toArray)

	def cubes : Iterable[Cube] = {
		val cubeClasses : Set[Class[_ <: Cube]] = reflector.getSubTypesOf(classOf[Cube]).toSet
		cubeClasses.map(_.newInstance()).toList
	}

	def environments : Iterable[Environment] = {
		val envClasses : Set[Class[_ <: Environment]] = reflector.getSubTypesOf(classOf[Environment]).toSet
		envClasses.map(_.newInstance()).toList
	}
}