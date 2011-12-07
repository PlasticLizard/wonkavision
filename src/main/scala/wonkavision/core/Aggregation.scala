package org.wonkavision.core

import scala.collection.immutable.SortedSet

class Aggregation(val name : String, val measures : Set[String], val cube : Cube) {
	
	private var dimensionSetList : Set[SortedSet[String]] = Set() 
	def aggregations = dimensionSetList

	def add(dimensions : String*) = {
		dimensionSetList += SortedSet(dimensions.toSeq:_*)
		this
	}

	def add(dimensionSets : List[Iterable[String]]) : Aggregation = {
		dimensionSets.foreach { dims => add(dims.toSeq:_*) }
		this
	}

	def combine(dimensions : String*) = {
		val combos = for (i <- dimensions.indices) yield dimensions.combinations(i+1)
		combos.flatten.foreach { dims => add(dims:_*) 	}
		this
	}

	def aggregateAll()  = {
		combine(cube.dimensionNames.toSeq:_*)
		this
	}


}