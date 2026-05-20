// attributes.sysml — Attribute definitions for the WorkflowModel campaign

package WorkflowModel {

    attribute def GeoCoordinate {
        attribute latitude  : Real;
        attribute longitude : Real;
        attribute altitude  : Real;
    }

    attribute def Velocity {
        attribute speed   : Real;
        attribute heading : Real;
    }

    attribute def BoundingBox {
        attribute minCoord : GeoCoordinate;
        attribute maxCoord : GeoCoordinate;
    }

    attribute def TimeInterval {
        attribute startTime : Real;
        attribute duration  : Real;
    }

} // end package WorkflowModel
