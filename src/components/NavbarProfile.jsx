import React, { useState, useEffect } from 'react';
import { Link, Navigate } from 'react-router-dom';
import '../Profile.css'; // Import the CSS file
import { backend } from "../declarations/backend";
import { AuthClient } from "@dfinity/auth-client";
import { canisterId, createActor } from "../declarations/backend";
import { Principal } from "@dfinity/principal";
import DoctorProfile from './DoctorProfile.jsx';

const NavbarProfile = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isBlurred, setIsBlurred] = useState(false);
  const [dob, setDob] = useState('');
  const [name, setName] = useState('');
  const [gender, setGender] = useState("");
  const [specialization, setSpecialization] = useState("");
  const [noofreq, setNoofreq] = useState(0);
  const [isLoading, setIsLoading] = useState(true);


  //authentication starts

  const [principal, setPrincipal] = useState("");
  const [isConnected, setIsConnected] = useState(false);
  const [loggedIn, setLoggedIn] = useState(false);
  const [isDoctor, setIsDoctor] = useState(false);
  const [isPatient, setIsPatient] = useState(false);
  let authClient;
  let actor;

  async function handleAuthenticated(authClient) {
    setIsConnected(true);
    const identity = await authClient.getIdentity();
    actor = createActor(canisterId, {
      agentOptions: {
        identity,
      },
    });
    var resp = await actor.isAccountExists();
    console.log(resp);
    if (resp.statusCode == BigInt(200)) {
      setPrincipal(resp.principal.toString());
      if (resp.msg == "null") {
        setLoggedIn(true);
        setIsConnected(true);
      } else if (resp.msg == "doctor") {
        setIsConnected(true);
        setIsDoctor(true);
        setLoggedIn(true);
      } else {
        setIsConnected(true);
        setIsPatient(true);
        setLoggedIn(true);
      }
    }
    console.log(isConnected, isDoctor, isPatient, loggedIn);
  }

  async function handleWalletClick() {
    var authClient = await AuthClient.create();
    if (await authClient.isAuthenticated()) {
      authClient.logout();
      window.location.href = "/";
    } else {
      authClient.login({
        maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
        identityProvider: process.env.DFX_NETWORK === "ic"
          ? "https://identity.ic0.app/#authorize"
          : `http://localhost:4943?canisterId=${process.env.CANISTER_ID_internet_identity}`,
        onSuccess: async () => {
          handleAuthenticated(authClient);
        },
      });
    }
  }

  async function reconnectWallet() {
    console.log("connec");
    authClient = await AuthClient.create();
    if (await authClient.isAuthenticated()) {
      await handleAuthenticated(authClient);
    } else {
      actor = backend;
    }

  }

  useEffect(() => {
    async function sendRequest() {
      await reconnectWallet();
      console.log("comple");
      setIsLoading(false);
      var resp = await actor.getDocDetails();
      console.log(resp);
      if (resp.statusCode == BigInt(200)) {
        var doc = resp.doc[0];
        setDob(doc.dob);
        setName(doc.name);
        setGender(Object.keys(doc.gender)[0]);
        setSpecialization(doc.specialization);
        setNoofreq(doc.requests.length);
      }
    }
    sendRequest();
  }, []);

  // authentication ends


  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
    setIsBlurred(!isBlurred); // Toggle the blur effect when the menu is opened/closed
  };
  const hamburger_class = isMenuOpen ? 'hamburger hamburger--spring is-active' : 'hamburger hamburger--spring';
  return (
    (isLoading == false) ? (

      <div className="navbar-container profile-body">
        {(!isDoctor) ? (<Navigate to="/" />) : (null)}

        <nav className="navbar"> {/* Use the class name directly */}
          <div className="logo">
            <img src="assets/logo.png" alt="Medisafe Logo" />
            <span className='nav-heading'>MEDISAFE</span>
          </div>
          <div className="profile">
            <img src="assets/profile.png" alt="Profile Pic" />
            {/* <span>Hello, {userName}</span> */}
            <button className={hamburger_class} type="button" onClick={toggleMenu}>
              <span className="hamburger-box">
                <span className="hamburger-inner"></span>
              </span>
            </button>
          </div>
        </nav>
        <DoctorProfile
          principal={principal}
          name={name}
          dob={dob}
          gender={gender}
          specialization={specialization}
          noofreq={noofreq}
          isBlurred={isBlurred} // Pass the blur state to the Profile component
        />
        <div className={`dropdown-menu ${isMenuOpen ? 'open' : ''}`}>
          <div className="dropdown-box">
            <Link className="button" to="/doctor_access">Patients dealed</Link>
            <Link className="button" to="/profile_qr">QR Scan</Link>
          </div>
          <div className="dropdown-box">
            <hr />
            <button className="button" onClick={handleWalletClick}>Logout</button>
            <div className="social-icons">
              <i className="fab fa-facebook"></i>
              <i className="fab fa-twitter"></i>
              <i className="fab fa-instagram"></i>
            </div>
          </div>
        </div>

      </div>
    ) : (<div>Loading...</div>)

  )
};

export default NavbarProfile;
