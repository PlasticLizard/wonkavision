package org.wonkavision.core

import measures._

import MeasureFormat._
import FactAction._

class Cube( val name : String ) {
		
	private var dimensionMap : Map[String, Dimension] = Map()
	private var measureMap : Map[String, Measure] = Map()
	private var aggregationMap : Map[String, Aggregation] = Map()
	private var eventList : List[FactEventBinding] = List()

	def dimensions = dimensionMap

	def dimensionNames = dimensionMap.keys

	def measures = measureMap

	def aggregations = aggregationMap

	def events = eventList


	def dimension(name : String,
		            key : String = null,
		            caption : String = null,
		            sort : String = null) {

		            addDimension( Dimension(name, key, caption, sort) )

	}

	def sum(names : String*) {
		measureMap = measureMap ++ names.map { name => ( name -> new Sum(name) ) }
	}	

	def calc(name : String,
				   format : MeasureFormat = MeasureFormat.Decimal)
				   (calc: () => Double) {

				   	addMeasure( new Calculation(name, format, calc) )
		
	}

	def aggregation(name : String, measures : List[String], config:(Aggregation) => Aggregation ) {

		val agg = new Aggregation(name, measures.toSet, this)
		config(agg)
		addAggregation(agg)

	}

	def accept(event : String, action : FactAction, transformation : MapTransformation = null) {
		val binding = FactEventBinding(event, action, this, transformation) 
		addEvent(binding)
	}

	protected def addDimension(dim : Dimension) =
		dimensionMap = dimensionMap + (dim.name -> dim)

	protected def addMeasure(measure : Measure) =
		measureMap = measureMap + (measure.name -> measure)

	protected def addAggregation(aggregation: Aggregation) =
		aggregationMap = aggregationMap + (aggregation.name -> aggregation)

	protected def addEvent(eventBinding: FactEventBinding) =
		eventList = eventBinding :: eventList


}	