import * as React from "react";
import { createRoot } from "react-dom/client";
import { Wrapper, Status } from "@googlemaps/react-wrapper";
import { createCustomEqual } from "fast-equals";
import { isLatLngLiteral } from "@googlemaps/typescript-guards";
import { useEffect } from "react";
const render = (status: Status) => {
  return <h1>{status}</h1>;
};

const App: React.VFC = () => {
  const balance = React.useState(100)
  // 打卡记录
  const [markers, setMarkers] = React.useState<google.maps.LatLng[]>([]);
  const [zoom, setZoom] = React.useState(14); // initial zoom
  // Set default location as Denver
  const [center, setCenter] = React.useState<google.maps.LatLngLiteral>({
    lat: 39.742043,
    lng: -104.991531,
  });
  const onIdle = (m: google.maps.Map) => {
    console.log(m.getCenter()!.toJSON());
    setZoom(m.getZoom()!);
    setCenter(m.getCenter()!.toJSON());
  };

  useEffect(() => {
    // 添加假数据
    setMarkers([
      { lat: 22.530225361050473, lng: 114.04592983689992 },
      { lat: 22.410322915397525, lng: 114.04712534447626 },
      { lat: 22.610322915397525, lng: 114.14712534447626 },
      { lat: 22.610322915397525, lng: 114.04712534447626 },
      { lat: 22.5965267524921, lng: 114.08441573923417 },
    ]);
    // 初始化获取当前的位置并将其置于中央位置
    try {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const pos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          setCenter(pos);
        },
        () => {}
      );
    } catch (error) {
      console.log(error);
    }
  }, []);
  // 记录当前坐标
  const handleRecord = () => {
    try {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const pos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          console.log("pos to mark: ", pos);
          setCenter(pos);
          setMarkers([...markers,pos]);
        },
        () => {}
      );
    } catch (error) {
      console.log(error);
    }
  };
  // handle Connect Wallet
  const handleConnectWallet= ()=>{

  }
  return (
    <div style={{ display: "flex", height: "100%" }}>
      <div class="header"  >
        <div>balance: {balance}</div>
        <button onClick={()=>handleConnectWallet()}>Connect Wallet</button>
      </div>
      <Wrapper
        apiKey={import.meta.env.VITE_GOOGLE_MAPS_API_KEY!}
        region='US'
        language="en"
        render={render}
      >
        <Map
        options={{
          zoomControl: false,
          mapTypeControl: false,
          scaleControl: false,
          streetViewControl: false,
          rotateControl: false,
          fullscreenControl: false
        }}
          center={center}
          onIdle={onIdle}
          zoom={zoom}
          style={{ flexGrow: "1", height: "100%" }}
        >
          {/* 遍历打卡点 */}
          {markers.map((latLng, i) => {
            return <Marker key={i} position={latLng} />;
          })}
        </Map>
      </Wrapper>
      <div class="footer">
        <button onClick={() => handleRecord()}>Check In!</button>
      </div>
    </div>
  );
};
interface MapProps extends google.maps.MapOptions {
  style: { [key: string]: string };
  onClick?: (e: google.maps.MapMouseEvent) => void;
  onIdle?: (map: google.maps.Map) => void;
  children?: React.ReactNode;
}

const Map: React.FC<MapProps> = ({
  onClick,
  onIdle,
  children,
  style,
  ...options
}) => {
  const ref = React.useRef<HTMLDivElement>(null);
  const [map, setMap] = React.useState<google.maps.Map>();

  React.useEffect(() => {
    if (ref.current && !map) {
      setMap(new window.google.maps.Map(ref.current, {}));
    }
  }, [ref, map]);

  // because React does not do deep comparisons, a custom hook is used
  // see discussion in https://github.com/googlemaps/js-samples/issues/946
  useDeepCompareEffectForMaps(() => {
    if (map) {
      map.setOptions(options);
    }
  }, [map, options]);

  React.useEffect(() => {
    if (map) {
      ["click", "idle"].forEach((eventName) =>
        google.maps.event.clearListeners(map, eventName)
      );

      if (onClick) {
        map.addListener("click", onClick);
      }

      if (onIdle) {
        map.addListener("idle", () => onIdle(map));
      }
    }
  }, [map, onClick, onIdle]);

  return (
    <>
      <div ref={ref} style={style} />
      {React.Children.map(children, (child) => {
        if (React.isValidElement(child)) {
          // set the map prop on the child component
          // @ts-ignore
          return React.cloneElement(child, { map });
        }
      })}
    </>
  );
};
// 打卡坐标
const Marker: React.FC<google.maps.MarkerOptions> = (options) => {
  const [marker, setMarker] = React.useState<google.maps.Marker>();

  React.useEffect(() => {
    if (!marker) {
      setMarker(new google.maps.Marker());
    }

    // remove marker from map on unmount
    return () => {
      if (marker) {
        marker.setMap(null);
      }
    };
  }, [marker]);

  React.useEffect(() => {
    if (marker) {
      marker.setOptions(options);
    }
  }, [marker, options]);

  return null;
};

const deepCompareEqualsForMaps = createCustomEqual(
  (deepEqual) => (a: any, b: any) => {
    if (
      isLatLngLiteral(a) ||
      a instanceof google.maps.LatLng ||
      isLatLngLiteral(b) ||
      b instanceof google.maps.LatLng
    ) {
      return new google.maps.LatLng(a).equals(new google.maps.LatLng(b));
    }

    // TODO extend to other types

    // use fast-equals for other objects
    return deepEqual(a, b);
  }
);

function useDeepCompareMemoize(value: any) {
  const ref = React.useRef();

  if (!deepCompareEqualsForMaps(value, ref.current)) {
    ref.current = value;
  }

  return ref.current;
}

function useDeepCompareEffectForMaps(
  callback: React.EffectCallback,
  dependencies: any[]
) {
  React.useEffect(callback, dependencies.map(useDeepCompareMemoize));
}

window.addEventListener("DOMContentLoaded", () => {
  const root = createRoot(document.getElementById("root")!);
  root.render(<App />);
});

export {};
