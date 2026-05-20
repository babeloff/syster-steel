// vehicle.sysml — tutorial example model used in Tutorials 2 and 3

package VehicleModel {

    part def VehicleSystem {
        attribute mass     : Real;
        attribute velocity : Real;

        part engine    : Engine;
        part chassis   : Chassis;
        port drivePort : DrivePort;
    }

    part def Engine {
        attribute power      : Real;
        attribute efficiency : Real;
        port fuelIn   : FuelPort;
        port driveOut : DrivePort;
    }

    part def Chassis {
        attribute weight : Real;
    }

    port def DrivePort;
    port def FuelPort;
}
