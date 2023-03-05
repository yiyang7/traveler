import { Loader } from "@googlemaps/js-api-loader";
import { useEffect, useState } from "react";
import "./style.css";
import "../utils/rem";

let featureLayer;
let infoWindow;
let map;
let loader;
let google;
const featureStyleOptions = {
  strokeColor: "#810FCB",
  strokeOpacity: 1.0,
  strokeWeight: 1.4,
  fillColor: "#810FCB",
  fillOpacity: 0.3,
};

const App = () => {
  // balance
  const [balance, updateBalance] = useState(0);
  const [checkList, setCheckList] = useState([]);
  const [heatmapList,setHeatmapList] = useState([])
  const [inited, setInit] = useState(false);
  const [markers, setMarkers] = useState([]);
  // fetch records
  const fetchData = () => {
    setCheckList(["ChIJzxcfI6qAa4cR1jaKJ_j0jhE"]);
    setMarkers([
      { lat: 39.695, lng: -104.988 },
      { lat: 39.675, lng: -104.995 },
      { lat: 39.665, lng: -104.966 },
      { lat: 39.78, lng:-104.999 },
    ]);
    setHeatmapList([
      { lat: 39.69145, lng: -104.9971 },
      { lat: 39.69245, lng: -104.9972 },
      { lat: 39.69345, lng: -104.9973 },
      { lat: 39.69445, lng: -104.9974 },
      { lat: 39.69545, lng: -104.9975 },
      { lat: 39.69645, lng: -104.9976 },
      { lat: 39.69745, lng: -104.9977 },
      { lat: 39.69845, lng: -104.9978 },
      { lat: 39.69945, lng: -104.9979 },
    ])
  };
  // check in
  const handleCheckIn = () => {
    try {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const pos = {
              lat: position.coords.latitude,
              lng: position.coords.longitude,
            };
            map.setCenter(pos);
            setMarkers([...markers, pos]);
            // highlight Denver
            setCheckList(["ChIJzxcfI6qAa4cR1jaKJ_j0jhE"]);
            updateBalance(balance + 10);
          },
          () => {
            handleLocationError(true, infoWindow, map.getCenter());
          }
        );
      } else {
        handleLocationError(false, infoWindow, map.getCenter());
      }
    } catch (error) {
      console.log(error);
    }
  };
  function handleLocationError(browserHasGeolocation, infoWindow, pos) {
    infoWindow.setPosition(pos);
    infoWindow.setContent(
      browserHasGeolocation
        ? "Error: The Geolocation service failed."
        : "Error: Your browser doesn't support geolocation."
    );
    infoWindow.open(map);
  }
  // heatmap
  const handleDrawHeatmap = ()=>{
    const list =  heatmapList.map(coords=>{
      return new google.maps.LatLng(coords.lat, coords.lng)
    })
    const heatmap = new google.maps.visualization.HeatmapLayer({
      data:list
    });
    heatmap.setMap(map);
  }
  // drawing
  const handleDrawArea = () => {
    if (featureLayer) {
      featureLayer.style = (options) => {
        // palaceId
        if (checkList.includes(options.feature.placeId)) {
          return featureStyleOptions;
        }
      };
    }
  };
  // init Map
  const initMap = async () => {
    try {
      loader = new Loader({
        apiKey: "",
        version: "beta",
        mapId: "c53551e361192a0f",
        language: "en",
        // libraries:['visualization'],
        libraries:['drawing', 'geometry', 'places', 'visualization']
      });
      //
      google = await loader.load();
      map = new google.maps.Map(document.getElementById("map"), {
        center: { lat: 39.69, lng: -104.98  }, // Park County, CO
        zoom: 13,
        mapId: "c53551e361192a0f",
        zoomControl: false,
        mapTypeControl: false,
        scaleControl: false,
        streetViewControl: false,
        rotateControl: false,
        fullscreenControl: false,
      });
      featureLayer = map.getFeatureLayer("LOCALITY");
      infoWindow = new google.maps.InfoWindow({});
      setTimeout(() => {
        setInit(true);
        fetchData();
      }, 1000);
    } catch (error) {
      
    }
 

  };
  // add marker
  const drawingMarker = (location, map) => {
    if (google) {
      new google.maps.Marker({
        position: location,
        map: map,
      });
    }
  };
  //
  const handleConnectWallet = () => {};
  useEffect(() => {
    setTimeout(()=>{
      initMap();
    })
  }, []);
  useEffect(() => {
    if (inited) {
      handleDrawArea();
    }
  }, [checkList]);
  useEffect(() => {
    if (inited) {
      markers.forEach((location) => {
        drawingMarker(location, map);
      });
    }
  }, [markers]);
  useEffect(() => {
    if (inited && heatmapList.length) {
      handleDrawHeatmap();
    }
  }, [heatmapList]);
  return (
    <div id="App">
      <header>
        <div>balance: {balance}</div>
        <button className="button" onClick={() => handleConnectWallet()}>
          Connect Wallet
        </button>
      </header>
      <div id="map"></div>
      <footer>
        <button className="button" onClick={() => handleCheckIn()}>
          Check In!
        </button>
      </footer>
    </div>
  );
};
export default App;
