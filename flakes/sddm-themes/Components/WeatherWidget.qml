import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: weatherWidget
    visible: config.WeatherWidgetEnabled === "true"

    // Position from config (set in .conf files)
    anchors {
        bottom: parent.bottom
        right: parent.right
        margins: config.WeatherMargin || 20
    }

    // Configuration-driven properties
    property string apiKey: config.WeatherApiKey || ""
    property string city: config.WeatherCity || "Melbourne,AU"
    property string units: config.WeatherUnits || "m" // Metric by default

    Text {
        id: weatherText
        color: config.WeatherTextColor || "#ffffff"
        font {
            family: config.Font || "pixelon"
            pixelSize: config.WeatherFontSize || 14
        }
        text: "🌡️ Loading..."
    }

    Timer {
        interval: config.WeatherRefreshInterval || 300000 // Default to 5 minutes
        running: parent.visible
        repeat: true
        onTriggered: updateWeather()
    }

    function updateWeather() {
        if (!apiKey) {
            weatherText.text = "❌ No API Key";
            return;
        }

        var xhr = new XMLHttpRequest();
        var url = `http://api.weatherstack.com/current?access_key=${apiKey}&query=${city}&units=${units}`;
        
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.success === false || response.error) {
                        weatherText.text = "⚠️ Weather Error";
                        console.log("Error fetching weather:", response.error.info);
                    } else {
                        var temp = response.current.temperature;
                        var desc = response.current.weather_descriptions[0];
                        weatherText.text = `🌡️ ${temp}°C | ${desc}`;
                    }
                } catch (e) {
                    weatherText.text = "⚠️ Parsing Error";
                    console.log("Error parsing weather data:", e);
                }
            }
        };
        xhr.send();
    }

    Component.onCompleted: if (visible) updateWeather()
}
