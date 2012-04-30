package org.wonkavision.server

import org.reflections.Reflections
import org.reflections.util.{ConfigurationBuilder,FilterBuilder,ClasspathHelper}
import org.reflections.scanners.SubTypesScanner
import scala.collection.JavaConversions._

import org.wonkavision.core.Cube

class CubeLoader(namespaces : String*) {
	val reflector = new Reflections(namespaces.toArray)

	def cubes : Iterable[Cube] = {
		val cubeClasses : Set[Class[_ <: Cube]] = reflector.getSubTypesOf(classOf[Cube]).toSet
		cubeClasses.map(_.newInstance()).toList
	}
}