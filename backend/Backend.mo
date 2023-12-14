import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import RBTree "mo:base/RBTree";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import LocalDateTime "mo:datetime/LocalDateTime";
import Debug "mo:base/Debug";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";

actor {

  type List<Text> = ?(Text, List<Text>);

  type Gender = {
    #Male;
    #Female;
  };

  type Record = {
    patientPrincipal : Principal;
    doctorPrincipal : Principal;
    addedOn : Time.Time;
    requestUUID : Text;
    prescription : Text;
    attachment : Blob;
  };

  type Doctor = {
    name : Text;
    dob : Text;
    gender : Gender;
    specialization : Text;
    requests : [Text];
  };

  type Patient = {
    name : Text;
    dob : Text;
    gender : Gender;
    doctors : [Principal];
    noofrecords : Nat;
    requests : [Text];
    records : [Record];
  };

  type RequestStatus = {
    #Complete;
    #Reject;
    #Accept;
    #Nota;
  };

  type Request = {
    patientPrincipal : Principal;
    doctorPrincipal : Principal;
    expries : Time.Time;
    note : Text;
    status : RequestStatus;
    isEmergency : Bool;
    requestedOn : Time.Time;
  };

  var patients = RBTree.RBTree<Principal, Patient>(Principal.compare);
  var doctors = RBTree.RBTree<Principal, Doctor>(Principal.compare);
  var requests = RBTree.RBTree<Text, Request>(Text.compare);

  // function to create a doctor account
  public shared (msg) func createDoctor(name : Text, dob : Text, gender : Gender, specialization : Text) : async {
    statusCode : Nat;
    msg : Text;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var doctor = doctors.get(msg.caller);
      switch (doctor) {
        case (null) {
          var patient = patients.get(msg.caller);
          switch (patient) {
            case (null) {
              var doctor : Doctor = {
                name = name;
                dob = dob;
                gender = gender;
                specialization = specialization;
                requests = [];
              };
              doctors.put(msg.caller, doctor);
              return {
                statusCode = 200;
                msg = "Registered as Doctor Successfully.";
              };
            };
            case (?patient) {
              return {
                statusCode = 403;
                msg = "A Patient Account Exists with this Identity";
              };
            };
          };
        };
        case (?user) {
          return {
            statusCode = 403;
            msg = "Doctor Already Exists with this Identity";
          };
        };
      };
    } else {
      return {
        statusCode = 404;
        msg = "Connect Wallet To Access This Function";
      };
    };
  };

  // function to create a patient account
  public shared (msg) func createPatient(name : Text, dob : Text, gender : Gender) : async {
    statusCode : Nat;
    msg : Text;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var patient = patients.get(msg.caller);
      switch (patient) {
        case (null) {
          var doctor = doctors.get(msg.caller);
          switch (doctor) {
            case (null) {
              var patient : Patient = {
                name = name;
                dob = dob;
                gender = gender;
                doctors = [];
                noofrecords = 0;
                requests = [];
                records = [];
              };
              patients.put(msg.caller, patient);
              return {
                statusCode = 200;
                msg = "Registered as Patient Successfully.";
              };
            };
            case (?doctor) {
              return {
                statusCode = 403;
                msg = "A Doctor Account Exists with this Identity";
              };
            };
          };
        };
        case (?patient) {
          return {
            statusCode = 403;
            msg = "Patient account Already Exists with this Identity";
          };
        };
      };
    } else {
      return {
        statusCode = 404;
        msg = "Connect Wallet To Access This Function";
      };
    };
  };

  // function to check whether caller has a account or not
  public shared query (msg) func isAccountExists() : async {
    statusCode : Nat;
    msg : Text;
    principal : Principal;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var patient = patients.get(msg.caller);
      switch (patient) {
        case (null) {
          var doctor = doctors.get(msg.caller);
          switch (doctor) {
            case (null) {
              return { statusCode = 200; msg = "null"; principal = msg.caller };
            };
            case (?doctor) {
              return {
                statusCode = 200;
                msg = "doctor";
                principal = msg.caller;
              };
            };
          };
        };
        case (?patient) {
          return { statusCode = 200; msg = "patient"; principal = msg.caller };
        };
      };
    } else {
      return {
        statusCode = 404;
        msg = "Connect Wallet To Access This Function";
        principal = msg.caller;
      };
    };
  };

  public shared query (msg) func getDocDetails() : async {
    statusCode : Nat;
    doc : ?Doctor;
    msg : Text;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var doctor = doctors.get(msg.caller);
      switch (doctor) {
        case (null) {
          return {
            statusCode = 403;
            doc = null;
            msg = "This identity doesn't have any Doctor Account";
          };
        };
        case (?doctor) {
          return {
            statusCode = 200;
            doc = ?doctor;
            msg = "Retrived Doctor Details Successsfully.";
          };
        };
      };
    } else {
      return {
        statusCode = 404;
        doc = null;
        msg = "Connect Wallet To Access This Function";
      };
    };
  };

  public shared query (msg) func getPatientDetails() : async {
    statusCode : Nat;
    patient : ?Patient;
    msg : Text;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var patient = patients.get(msg.caller);
      switch (patient) {
        case (null) {
          return {
            statusCode = 403;
            patient = null;
            msg = "This identity doesn't have any Patient Account";
          };
        };
        case (?patient) {
          return {
            statusCode = 200;
            patient = ?patient;
            msg = "Retrived Patient Details Successsfully.";
          };
        };
      };
    } else {
      return {
        statusCode = 404;
        patient = null;
        msg = "Connect Wallet To Access This Function";
      };
    };
  };

  public shared query (msg) func doctorScan(principal : Text) : async {
    statusCode : Nat;
    patient : ?{
      name : Text;
      dob : Text;
      gender : Gender;
      noofrecords : Nat;
    };
    msg : Text;
    is_having_access : Bool;
    is_having_emergency : Bool;
    is_pending : Bool;
    request : ?Request;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var doctor = doctors.get(msg.caller);
      switch (doctor) {
        case (null) {
          return {
            statusCode = 403;
            patient = null;
            msg = "Only Doctors can Access this method";
            is_having_access = false;
            is_having_emergency = false;
            is_pending = false;
            request = null;
          };
        };
        case (?doctor) {
          var patient_principal = Principal.fromText(principal);
          var patient = patients.get(patient_principal);
          switch (patient) {
            case (null) {
              return {
                statusCode = 403;
                patient = null;
                msg = "Invalid Patient QR Code Scanned.";
                is_having_access = false;
                is_having_emergency = false;
                is_pending = false;
                request = null;
              };
            };
            case (?patient) {
              var is_having_access = false;
              var is_having_emergency = false;
              var is_pending = false;
              var request_codes = Array.reverse(patient.requests);
              var req_ob : ?Request = null;
              label name for (request_code in request_codes.vals()) {
                req_ob := requests.get(request_code);
                switch (req_ob) {
                  case (null) {
                    continue name;
                  };
                  case (?req_ob) {
                    if (req_ob.doctorPrincipal == msg.caller) {
                      if ((req_ob.status == #Nota or req_ob.status == #Accept) and req_ob.isEmergency) {
                        is_having_emergency := true;
                      } else if (req_ob.status == #Accept and (not req_ob.isEmergency)) {
                        is_having_access := true;
                      } else if (req_ob.status == #Nota) {
                        is_pending := true;
                      };
                    };
                  };
                };

                if (is_having_access or is_having_emergency or is_pending) {
                  break name;
                };

              };
              var hiddenpatient = {
                name = patient.name;
                dob = patient.dob;
                gender = patient.gender;
                noofrecords = patient.noofrecords;
              };
              return {
                statusCode = 200;
                patient = ?hiddenpatient;
                msg = "Retrived Scan Details Successfully.";
                is_having_access = is_having_access;
                is_having_emergency = is_having_emergency;
                is_pending = is_pending;
                request = req_ob;
              };
            };
          };
        };
      };
    } else {
      return {
        statusCode = 404;
        patient = null;
        msg = "Connect Wallet To Access This Function";
        is_having_access = false;
        is_having_emergency = false;
        is_pending = false;
        request = null;
      };
    };
  };

  public shared (msg) func addRequest(principal : Text, isEmergency : Bool, note : Text) : async {
    statusCode : Nat;
    msg : Text;
  } {
    if (not Principal.isAnonymous(msg.caller)) {
      var doctor = doctors.get(msg.caller);
      switch (doctor) {
        case (null) {
          return {
            statusCode = 403;
            msg = "Only Doctors can Access this method";
          };
        };
        case (?doctor) {
          var patientPrincipal = Principal.fromText(principal);
          var patient = patients.get(patientPrincipal);
          switch (patient) {
            case (null) {
              return {
                statusCode = 403;
                msg = "Invalid Patient Principal.";
              };
            };
            case (?patient) {
              var is_having_access = false;
              var is_having_emergency = false;
              var is_pending = false;
              var request_codes = Array.reverse(patient.requests);
              var req_ob : ?Request = null;
              label name for (request_code in request_codes.vals()) {
                req_ob := requests.get(request_code);
                switch (req_ob) {
                  case (null) {
                    continue name;
                  };
                  case (?req_ob) {
                    if (req_ob.doctorPrincipal == msg.caller) {
                      if ((req_ob.status == #Nota or req_ob.status == #Accept) and req_ob.isEmergency) {
                        is_having_emergency := true;
                      } else if (req_ob.status == #Accept and (not req_ob.isEmergency)) {
                        is_having_access := true;
                      } else if (req_ob.status == #Nota) {
                        is_pending := true;
                      };
                    };
                  };
                };

                if (is_having_access or is_having_emergency or is_pending) {
                  break name;
                };

              };

              if (is_having_access or is_having_emergency or is_pending) {
                return {
                  statusCode = 400;
                  msg = "Failed to Request, as there is an active Request Available to this Patient.";
                };
              };

              var req : Request = {
                patientPrincipal = patientPrincipal;
                doctorPrincipal = msg.caller;
                expries = 0;
                note = note;
                status = #Nota;
                isEmergency = isEmergency;
                requestedOn = Time.now();
              };

              let g = Source.Source();
              var uuid = UUID.toText(await g.new());

              requests.put(uuid, req);

              var doct_req = doctor.requests;
              var patient_req = patient.requests;

              var new_doct_req = Array.append<Text>(doct_req, Array.make<Text>(uuid));
              var new_patient_req = Array.append<Text>(patient_req, Array.make<Text>(uuid));

              var newDoctor : Doctor = {
                name = doctor.name;
                dob = doctor.dob;
                gender = doctor.gender;
                specialization = doctor.specialization;
                requests = new_doct_req;
              };

              var newPatient : Patient = {
                name = patient.name;
                dob = patient.dob;
                gender = patient.gender;
                doctors = patient.doctors;
                noofrecords = patient.noofrecords;
                requests = new_patient_req;
                records = patient.records;
              };

              doctors.put(msg.caller, newDoctor);
              patients.put(patientPrincipal, newPatient);

              return {
                statusCode = 200;
                msg = "Request Sent to the Patient Successfully.";
              };

            };
          };
        };
      };

    } else {
      return {
        statusCode = 404;
        msg = "Connect Wallet To Access This Function";
      };
    };
  };

  public shared query (msg) func doctorAccess() : async {
    statusCode : Nat;
    msg : Text;
    data : ?[{
      patient_name : Text;
      patient_dob : Text;
      access_type : Text;
      access_endson : ?Time.Time;
      request_access : RequestStatus;
      writeable : Text;
      patient_history : ?[{
        past_prescription : Text;
        addedby : Text;
        addedon : Time.Time;
        attachments : Blob;
      }];
    }];
  } {

    if (not Principal.isAnonymous(msg.caller)) {
      var doctor = doctors.get(msg.caller);
      switch (doctor) {
        case (null) {
          return {
            statusCode = 403;
            msg = "Only Doctors can Access this method";
            data=null;
          };
        };
        case (?doctor) {
          var access_recs = Buffer.Buffer<{ patient_name : Text; patient_dob : Text; access_type : Text; access_endson : ?Time.Time; request_access : RequestStatus; writeable : Text; patient_history : ?[{ past_prescription : Text; addedby : Text; addedon : Time.Time; attachments : Blob }] }>(Array.size<Text>(doctor.requests));
          label name for (requestUUID in doctor.requests.vals()) {
            var request = requests.get(requestUUID);
            switch (request) {
              case (null) {
                continue name;
              };
              case (?request) {
                var patient = patients.get(request.patientPrincipal);
                switch (patient) {
                  case (null) {
                    continue name;
                  };
                  case (?patient) {
                    var patient_name = patient.name;
                    var patient_dob = patient.dob;
                    var access_type = if (not request.isEmergency) { "Normal" } else { "Emergency" };
                    var access_endson : ?Time.Time = null;
                    var request_access = request.status;
                    var writeable = "no";
                    var patient_history : ?[{
                      past_prescription : Text;
                      addedby : Text;
                      addedon : Time.Time;
                      attachments : Blob;
                    }] = null;
                    if (
                      (request.isEmergency and (request.status == #Nota or request.status == #Accept)) or
                      (not request.isEmergency and (request.status == #Accept))
                    ) {
                      writeable := "yes";
                      access_endson := ?request.expries;
                      var patient_rec = Buffer.Buffer<{ past_prescription : Text; addedby : Text; addedon : Time.Time; attachments : Blob }>(Array.size<Record>(patient.records));
                      for (record in patient.records.vals()) {
                        var addedby = "";
                        var d = doctors.get(record.doctorPrincipal);
                        switch (d) {
                          case (null) { addedby := "" };
                          case (?d) { addedby := d.name };
                        };
                        patient_rec.add({
                          past_prescription = record.prescription;
                          addedby = addedby;
                          addedon = record.addedOn;
                          attachments = record.attachment;
                        });
                      };
                      patient_history := ?Buffer.toArray(patient_rec);
                    };

                    access_recs.add({
                      patient_name = patient_name;
                      patient_dob = patient_dob;
                      access_type = access_type;
                      access_endson = access_endson;
                      request_access = request_access;
                      writeable = writeable;
                      patient_history = patient_history;
                    })

                  };
                };

              };
            };
          };

          return {
            statusCode = 200;
            msg = "Retrived Request History Successfully.";
            data = ?Buffer.toArray(access_recs);
          };
        };
      };
    } else {
      return {
        statusCode = 404;
        msg = "Connect Wallet To Access This Function";
        data = null;
      };
    };

  };

  public shared query (msg) func patientRequests() : async {
    statusCode : Nat;
    msg:Text;
    
  } {

  };

  /* Stabling Users Data While Cannister Upgrade */

  type StablePatient = (Principal, Patient); // type to hold stable user

  type StableDoctor = (Principal, Doctor);

  type StableRequest = (Text, Request);

  stable var serializedPatients : [StablePatient] = [];

  stable var serializedDoctors : [StableDoctor] = []; // stable variable to hold doctors

  stable var serializedRequests : [StableRequest] = [];

  func serailize() {
    // function to store users in stable variable while upgrade
    serializedPatients := Iter.toArray(patients.entries());
    serializedDoctors := Iter.toArray(doctors.entries());
    serializedRequests := Iter.toArray(requests.entries());

  };

  func deserialize() {
    // function to store users from stable variable to RBTree after upgrade

    var newPatients = RBTree.RBTree<Principal, Patient>(Principal.compare);
    var newDoctors = RBTree.RBTree<Principal, Doctor>(Principal.compare);
    var newRequests = RBTree.RBTree<Text, Request>(Text.compare);

    let tuplesPatients = Iter.fromArray(serializedPatients);
    let tuplesDoctors = Iter.fromArray(serializedDoctors);
    let tuplesRequests = Iter.fromArray(serializedRequests);

    for (tuple in tuplesPatients) {
      let (key, value) = tuple;
      newPatients.put(key, value);
    };
    patients := newPatients;

    for (tuple in tuplesDoctors) {
      let (key, value) = tuple;
      newDoctors.put(key, value);
    };
    doctors := newDoctors;

    for (tuple in tuplesRequests) {
      let (key, value) = tuple;
      newRequests.put(key, value);
    };
    requests := newRequests;

  };

  system func preupgrade() {
    serailize();
  };

  system func postupgrade() {
    deserialize();
  };

};
