import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hospital_service/src/helpers/current_location.dart';
import 'package:hospital_service/src/helpers/dimensions.dart';
import 'package:hospital_service/src/models/hospital.dart';
import 'package:hospital_service/src/providers/hospital_list_provider.dart';
import 'package:hospital_service/src/providers/location_provider.dart';
import 'package:hospital_service/src/widgets/hospital_listview_item.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  List<Hospital> hospitals;
  HospitalListProvider hospitalListProvider;
  Completer<GoogleMapController> _controller = Completer();
  LocationData myLocationData;
  LocationProvider locationProvider;
  CameraPosition myPosition;
  Set<Marker> markers = Set<Marker>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PanelController controller = new PanelController();
    locationProvider = Provider.of<LocationProvider>(context);
    hospitalListProvider = Provider.of<HospitalListProvider>(context);
    hospitals = hospitalListProvider.getHospitalsList;
    for (Hospital hospital in hospitals) {
      markers.add(Marker(
          visible: true,
          position: LatLng(hospital.getLatitude, hospital.getLongitude),
          markerId: MarkerId("Taj Mahal"),
          infoWindow: InfoWindow(title: hospital.getName)));
    }
    myLocationData = locationProvider.getLocation;
    myPosition = CameraPosition(
      bearing: 192,
      target: LatLng(myLocationData.latitude, myLocationData.longitude),
      tilt: 0,
      zoom: 18,
    );
    return new Scaffold(
      appBar: AppBar(
        title: Text(
          "Hospital Service",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Montserrat",
            fontSize: 25,
          ),
        ),
        centerTitle: true,
      ),
      body: SlidingUpPanel(
        controller: controller,
        borderRadius: BorderRadius.circular(40),
        backdropEnabled: true,
        panel: Column(
          children: <Widget>[
            Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
                child: Container(
                    width: getViewportWidth(context),
                    height: getViewportHeight(context) * 0.1,
                    child: Center(
                      child: Text("Hospitals",
                          style: TextStyle(
                              fontSize: 40, fontFamily: "Montserrat")),
                    ))),
            ListView.builder(
              addAutomaticKeepAlives: false,
              physics: ScrollPhysics(), // to disable GridView's scrolling
              shrinkWrap: true,
              itemBuilder: (context, int index) {
                return HospitalListViewItem(
                  panelController: controller,
                  controller: _controller,
                  hospital: hospitals[index],
                );
              },
              itemCount: hospitals.length,
            )
          ],
        ),
        body: Center(
          child: Container(
              child: GoogleMap(
            buildingsEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            trafficEnabled: true,
            mapType: MapType.hybrid,
            compassEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            initialCameraPosition: myPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          )),
        ),
      ),
    );
  }

  Future<void> _currentLocation() async {
    final GoogleMapController controller = await _controller.future;
    await getLocation().then((value) {
      if (value != null) {
        locationProvider.setLocation = value;
        myLocationData = value;
        myPosition = CameraPosition(
          bearing: 192,
          target: LatLng(myLocationData.latitude, myLocationData.longitude),
          tilt: 0,
          zoom: 18,
        );
        controller.animateCamera(CameraUpdate.newCameraPosition(myPosition));
      }
    });
  }
}