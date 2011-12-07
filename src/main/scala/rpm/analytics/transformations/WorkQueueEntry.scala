package rpm.analytics.transformations

import org.wonkavision.core.MapTransformation

class WorkQueueEntry extends MapTransformation {
	def	map = {
		
    string  ("id")

    child ("team") {
			strings ("id", "name")
		}		

		child ("assigned_to") {
			string ("id", default="Unknown")
			string ("name", default="Unknown")
		}

    child ("work_queue_priority", source("work_queue")){
      int ("priority")
      string ("name", "Priority " + source("priority"))
      string ("key", source("priority"))
    }

    child ("work_queue") {
    	strings ("id", "name")
    	int ("priority")
    }

    include ( new WorkQueueEntryDynamic )
    
	}
}
