package rpm.analytics.transformations

import org.wonkavision.core.MapTransformation
import org.wonkavision.core.Convert
import org.scala_tools.time.Imports._

class WorkQueueEntryDynamic(val contextTime : DateTime = DateTime.now)
	extends MapTransformation {   

	def map() {
		
		val contextDate = formatDate (contextTime, ISO_DAY)
		val startDate =   formatDate ("due_date")
		val endDate =     formatDate ("completed_time")
		val overdueDate = formatDate ("overdue_date")
		
		val isActive = contextDate >= startDate &&
									 (endDate == null || contextDate <= endDate)
	
		bool ("is_active", isActive)

		count ("available") { isActive == true && endDate == null }
		
		count ("expiring_today") {
			overdueDate != null && 
			overdueDate == contextDate &&
			(endDate == null || overdueDate < endDate)
		}

		count ("incoming") { startDate == contextDate }
		count ("outgoing") { endDate == contextDate }
		
		count ("completed") {
			endDate != null &&
			endDate == contextDate &&
			getString("resolution", default = "").get == "completed"
		}
		
		count ("cancelled") {
			endDate != null &&
			endDate == contextDate &&
			getString("resolution", default = "").get != "completed"
		}

		count ("overdue") {
			isActive &&
			overdueDate != null &&
			overdueDate < contextDate &&
			endDate != contextDate &&
			(endDate == null || overdueDate < endDate)
		}
		
		child ("status") {
			string ("status", detectStatus(contextDate, startDate, endDate))
			int ("sort", statusSort(target("status")))	
		}

	}

  //overload MapTransformation#count to make the default value null, not 0
	def count(fieldName : String)(pred : => Boolean) : Unit = count(fieldName, default = None)(pred)

	def formatDate(fieldName: String, format: String = ISO_DAY) : String =
		if (fieldName.matches(".+_date")) {
			val outstr = getString(fieldName)
			if (outstr.isEmpty) null else outstr.get.substring(0,10)
		} else {
			formatDate(getDate(fieldName), format)
		}

	def detectStatus(contextDate : String, startDate : String, endDate : String) : String = {
		if (contextDate < startDate) {
			"scheduled"
		} else if (endDate != null && endDate < contextDate) {
			"closed"
		} else if (parentTarget("completed") != null) {
			"completed"
		} else if (parentTarget("cancelled") != null) {
			"cancelled"
		} else if (parentTarget("overdue") != null) {
			"overdue"
		} else {
			"ready"
		}
	}

	def statusSort(status : Any) = Array("ready", "expires_today",
																			 "overdue", "completed",
																			 "cancelled",	"scheduled",
																			 "unknown").indexOf(status.toString)

}
