import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hospitality/src/dialogs/loading_dialog.dart';
import 'package:hospitality/src/helpers/dimensions.dart';
import 'package:hospitality/src/helpers/fetch_user_data.dart';
import 'package:hospitality/src/models/appointment.dart';
import 'package:hospitality/src/models/hospital.dart';
import 'package:hospitality/src/models/user.dart';
import 'package:hospitality/src/providers/hospital_user_provider.dart';
import 'package:hospitality/src/providers/user_profile_provider.dart';
import 'package:hospitality/src/resources/network/network_repository.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HospitalStats extends StatefulWidget {
  HospitalStats();

  @override
  _HospitalStatsState createState() => _HospitalStatsState();
}

class _HospitalStatsState extends State<HospitalStats> {
  HospitalUserProvider hospitalUserProvider;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final TextStyle whiteText = TextStyle(color: Colors.white);
  double viewportHeight;
  double viewportWidth;
  int confirmedAppointments = 0;
  int rejectedAppointments = 0;
  int waitingAppointments = 0;
  bool availability = false;
  TextEditingController totalBedsController = TextEditingController();
  TextEditingController availableBedsController = TextEditingController();
  TextEditingController totalDoctorsController = TextEditingController();
  TextEditingController availableDoctorsController = TextEditingController();
  List<Appointment> appointmentsList = List<Appointment>();

  _HospitalStatsState();

  @override
  Widget build(BuildContext context) {
    viewportHeight = getViewportHeight(context);
    viewportWidth = getViewportWidth(context);
    hospitalUserProvider = Provider.of<HospitalUserProvider>(context);
    hospitalUserProvider.addListener(() {
      totalBedsController.text =
          hospitalUserProvider.getHospital.getTotalBeds.toString();
      availableBedsController.text =
          hospitalUserProvider.getHospital.getAvailableBeds.toString();
      totalDoctorsController.text =
          hospitalUserProvider.getHospital.getTotalDoctors.toString();
      availableDoctorsController.text =
          hospitalUserProvider.getHospital.getAvailableDoctors.toString();
      this.availability = hospitalUserProvider.getHospital.getAvailability;
    });

    return Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchHospitalUserData(
                context: context, hospitalUserProvider: hospitalUserProvider);
            await fetchAppointmentsList();
          },
          key: refreshIndicatorKey,
          child: _buildBody(context),
        ));
  }

  Widget _buildBody(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: ListView(
        addAutomaticKeepAlives: true,
        shrinkWrap: true,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                left: viewportWidth * 0.05, top: viewportWidth * 0.05),
            child: Text(
              "Appointment Stats:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: viewportWidth * 0.06,
                  fontFamily: "BalooTamma2"),
            ),
          ),
          SizedBox(
            height: viewportHeight * 0.015,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: viewportWidth * 0.04),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _buildTile(
                    color: Colors.green,
                    icon: Icons.portrait,
                    title: "Confirmed",
                    data: this.confirmedAppointments.toString(),
                  ),
                ),
                SizedBox(width: viewportWidth * 0.025),
                Expanded(
                  child: _buildTile(
                    color: Colors.red,
                    icon: Icons.portrait,
                    title: "Waiting",
                    data: this.waitingAppointments.toString(),
                  ),
                ),
                SizedBox(width: viewportWidth * 0.025),
                Expanded(
                  child: _buildTile(
                    color: Colors.pink,
                    icon: Icons.portrait,
                    title: "Rejected",
                    data: this.rejectedAppointments.toString(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: viewportWidth * 0.025),
          Divider(),
          Padding(
            padding: EdgeInsets.only(
                left: viewportWidth * 0.05, top: viewportWidth * 0.1),
            child: Text(
              "Availability Stats:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: viewportWidth * 0.06,
                  fontFamily: "BalooTamma2"),
            ),
          ),
          SizedBox(
            height: viewportHeight * 0.02,
          ),
          Padding(
            padding: EdgeInsets.only(left: viewportWidth * 0.05),
            child: Text(
              "Beds:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: viewportWidth * 0.05,
                  fontFamily: "Poppins"),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: viewportWidth * 0.04,
                vertical: viewportHeight * 0.01),
            child: _buildPercentIndicator(
                hospitalUserProvider.getHospital.getAvailableBeds,
                hospitalUserProvider.getHospital.getTotalBeds,
                "Beds"),
          ),
          SizedBox(
            height: viewportHeight * 0.02,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: viewportWidth * 0.05),
            child: Divider(),
          ),
          Padding(
            padding: EdgeInsets.only(left: viewportWidth * 0.05),
            child: Text(
              "Doctors:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: viewportWidth * 0.05,
                  fontFamily: "Poppins"),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: viewportWidth * 0.04,
                vertical: viewportHeight * 0.01),
            child: _buildPercentIndicator(
                hospitalUserProvider.getHospital.getAvailableDoctors,
                hospitalUserProvider.getHospital.getTotalDoctors,
                "Doctors"),
          ),
          SizedBox(
            height: viewportHeight * 0.04,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: viewportWidth * 0.04,
                vertical: viewportHeight * 0.01),
            child: _buildButtons(),
          ),
          SizedBox(height: viewportHeight * 0.03),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <
        Widget>[
      Expanded(
          child: Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, viewportWidth * 0.02, 0),
              child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                      text: "Availability: ",
                      style: TextStyle(
                          fontSize: viewportHeight * 0.02,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Manrope"),
                      children: <TextSpan>[
                        TextSpan(
                          text: (this.availability)
                              ? "Available"
                              : "Not Available",
                          style: TextStyle(
                              fontSize: viewportHeight * 0.02,
                              color: (this.availability)
                                  ? Colors.blue
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Poppins"),
                        )
                      ])))),
      Padding(
          padding: EdgeInsets.fromLTRB(0, 0, viewportWidth * 0.1, 0),
          child: CupertinoSwitch(
            value: this.availability,
            onChanged: (bool value) {
              setState(() {
                this.availability = value;
              });
            },
            activeColor: Colors.blue,
          )),
      VerticalDivider(),
      RaisedButton(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          splashColor: Colors.white,
          color: Colors.blue,
          child: Container(
            width: viewportWidth * 0.3,
            height: viewportHeight * 0.06,
            alignment: Alignment.center,
            child: Text(
              'Save',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: "Manrope",
                fontSize: viewportHeight * 0.020,
              ),
            ),
          ),
          textColor: Colors.white,
          onPressed: () async {
            showLoadingDialog(context: context);
            Hospital hospital = hospitalUserProvider.getHospital;
            hospital.setAvailableBeds = int.parse(availableBedsController.text);
            hospital.setAvailableDoctors =
                int.parse(availableDoctorsController.text);
            hospital.setTotalBeds = int.parse(totalBedsController.text);
            hospital.setTotalDoctors = int.parse(totalDoctorsController.text);
            hospital.setAvailability = this.availability;
            await getNetworkRepository
                .updateHospitalUserData(hospital: hospital)
                .then((value) {
              if (value.statusCode == 200) {
                Fluttertoast.showToast(
                  msg: "Profile Updated",
                );
                hospitalUserProvider.setHospital = hospital;
                Navigator.of(context, rootNavigator: true).pop('dialog');
              } else {
                Navigator.of(context, rootNavigator: true).pop('dialog');

                Fluttertoast.showToast(
                  msg: "Error in updating profile",
                );
                print(
                    "Update Profile Hospital: ${value.statusCode.toString() + value.body.toString()}");
              }
            }).catchError((error) {
              print("Update Profile Hospital: ${error.toString()}");
              Navigator.of(context, rootNavigator: true).pop('dialog');
            });
            refreshIndicatorKey.currentState.show();
          }),
    ]);
  }

  Widget _buildPercentIndicator(int numerator, int denominator, String value) {
    double result = 0;
    if (denominator == 0 || numerator == 0) {
      result = 0;
    } else {
      result = numerator / denominator;
    }
    return Column(
      children: <Widget>[
        LinearPercentIndicator(
          animation: true,
          percent: result,
          progressColor: Colors.blue,
          lineHeight: viewportHeight * 0.018,
          animateFromLastPercent: true,
          animationDuration: 1500,
          trailing: Container(
              margin: EdgeInsets.only(left: viewportWidth * 0.04),
              child: Text(
                "$numerator/$denominator",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Manrope",
                    fontSize: viewportWidth * 0.04),
              )),
          linearStrokeCap: LinearStrokeCap.roundAll,
        ),
        SizedBox(height: viewportHeight * 0.01),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(children: <Widget>[
              Text(
                "Total $value",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Manrope",
                    fontSize: viewportWidth * 0.04),
              ),
              _buildAdjuster("Total", value),
            ]),
            Column(children: <Widget>[
              Text(
                "Available $value",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Manrope",
                    fontSize: viewportWidth * 0.04),
              ),
              _buildAdjuster("Available", value),
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildAdjuster(String firstType, String secondType) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      IconButton(
        icon: Icon(Icons.remove_circle_outline),
        onPressed: () {
          setState(() {
            (firstType == "Available"
                    ? secondType == "Beds"
                        ? availableBedsController
                        : availableDoctorsController
                    : secondType == "Beds"
                        ? totalBedsController
                        : totalDoctorsController)
                .text = (int.parse((firstType == "Available"
                            ? secondType == "Beds"
                                ? availableBedsController
                                : availableDoctorsController
                            : secondType == "Beds"
                                ? totalBedsController
                                : totalDoctorsController)
                        .text) -
                    1)
                .toString();
          });
        },
        color: Colors.blue,
      ),
      Container(
          width: viewportWidth * 0.15,
          child: TextField(
            controller: firstType == "Available"
                ? secondType == "Beds"
                    ? availableBedsController
                    : availableDoctorsController
                : secondType == "Beds"
                    ? totalBedsController
                    : totalDoctorsController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          )),
      IconButton(
        icon: Icon(Icons.add_circle_outline),
        onPressed: () {
          setState(() {
            (firstType == "Available"
                    ? secondType == "Beds"
                        ? availableBedsController
                        : availableDoctorsController
                    : secondType == "Beds"
                        ? totalBedsController
                        : totalDoctorsController)
                .text = (int.parse((firstType == "Available"
                            ? secondType == "Beds"
                                ? availableBedsController
                                : availableDoctorsController
                            : secondType == "Beds"
                                ? totalBedsController
                                : totalDoctorsController)
                        .text) +
                    1)
                .toString();
          });
        },
        color: Colors.blue,
      ),
    ]);
  }

  Widget _buildTile({Color color, IconData icon, String title, String data}) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.all(viewportWidth * 0.02),
        height: viewportHeight * 0.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          color: color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Icon(
              icon,
              color: Colors.white,
            ),
            Text(
              title,
              style: whiteText.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: "Manrope",
                  fontSize: viewportHeight * 0.02),
            ),
            Text(
              data,
              style: whiteText.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  fontFamily: "BalooTamma2"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchAppointmentsList() async {
    await getNetworkRepository.getAppointmentsList().then((value) async {
      if (value.statusCode == 200) {
        rejectedAppointments=0;
        waitingAppointments=0;
        confirmedAppointments=0;
        setState(() {
          List<dynamic> responseList = json.decode(value.body);
          Map<String, dynamic> temp;
          appointmentsList = List<Appointment>();
          for (temp in responseList) {
            Appointment appointment = Appointment.fromJSON(temp);
            appointmentsList.add(appointment);
            setState(() {
              if (appointment.getStatus == "Confirmed" ||
                  appointment.getStatus == "confirmed") {
                confirmedAppointments++;
              } else if (appointment.getStatus == "Pending" ||
                  appointment.getStatus == "pending") {
                waitingAppointments++;
              } else if (appointment.getStatus == "Rejected" ||
                  appointment.getStatus == "rejected") {
                rejectedAppointments++;
              }
            });
          }
        });
      } else if (value.statusCode == 401) {
        print("Get Hospital Data: ${value.statusCode} Unauthorized access");
        Hospital hospital = Hospital();
        HospitalUserProvider hospitalUserProvider =
            Provider.of<HospitalUserProvider>(context);
        hospitalUserProvider.setHospital = hospital;
        UserProfileProvider userProfileProvider =
            Provider.of<UserProfileProvider>(context);
        User user = User();
        userProfileProvider.setUser = user;
        SharedPreferences preferences = await SharedPreferences.getInstance();
        await preferences.clear();
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/auth", (Route<dynamic> route) => false);
      } else {
        print(
            "Get Appointments List: ${value.statusCode.toString()} ${value.body.toString()}");
        Fluttertoast.showToast(msg: "Error in fetching appointments list");
      }
    }).catchError((error) {
      print("Get Appointments List: ${error.toString()}");
      Fluttertoast.showToast(msg: "Error in fetching appointments list");
    });
    return null;
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () async {
      if (mounted &&
          refreshIndicatorKey.currentState.mounted &&
          refreshIndicatorKey != null) {
        await refreshIndicatorKey.currentState.show();
      }
    });
  }
}
