<script setup>
let cityname;
let chart;



function getCoordinates(cityname) {
    const url = `https://nominatim.openstreetmap.org/search?q=${cityname}&format=json`;
    fetch(url)
        .then(response => response.json())
        .then(data => {
            const lat = data[0].lat;
            const lon = data[0].lon;
            getTemperature(lat, lon);
        })
        .catch(error => console.log(error));
}

function getTemperature(lat, lon) {
    const url = `https://archive-api.open-meteo.com/v1/era5?latitude=${lat}&longitude=${lon}&start_date=1960-01-01&end_date=2021-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max&timezone=Europe%2FBerlin`;
    fetch(url)
        .then(response => response.json())
        .then(data => {
            const historical = {};
            for (let i = 0; i < data.daily.time.length; i++) {
            const date = data.daily.time[i];
            const temperature = data.daily.temperature_2m_max[i];
            const temperatureMin = data.daily.temperature_2m_min[i]
            const precipitation = data.daily.precipitation_sum[i];
            const windspeed = data.daily.windspeed_10m_max[i];
            historical[date] = {
                temperature,
                precipitation,
                windspeed,
                temperatureMin
            };
            }
            
            const labels = Object.keys(historical);
            const temperatures = Object.values(historical).map(item => item.temperature);
            const precipitations = Object.values(historical).map(item => item.precipitation);
            const temperaturesMin = Object.values(historical).map(item => item.temperatureMin);
            const windspeeds = Object.values(historical).map(item => item.windspeed);
            
            if (chart) {
                chart.destroy();
            }
            chart = new Chart(myChart, {
                type: 'line',
                data: {
                    labels,
                    datasets: [
                    {
                        label: 'Temperature Max',
                        data: temperatures,
                        backgroundColor: 'rgba(255, 99, 132, 0.2)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Temperature Min',
                        data: temperaturesMin,
                        backgroundColor: 'rgba(0, 99, 132, 0.2)',
                        borderColor: 'rgba(0, 99, 132, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Precipitation 24H',
                        data: precipitations,
                        backgroundColor: 'rgba(122, 99, 132, 0.2)',
                        borderColor: 'rgba(122, 99, 132, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Wind Speed Max',
                        data: windspeeds,
                        backgroundColor: 'rgba(35, 99, 132, 0.2)',
                        borderColor: 'rgba(35, 99, 132, 1)',
                        borderWidth: 1
                    },
                    ]
                    
                },
                
                options: {
                    scales: {
                        yAxes: [{
                            ticks: {
                                beginAtZero: true
                            }
                        }]
                    },
                    plugins: {
                        zoom: {
                        // Container for pan options
                            pan: {
                            // Boolean to enable panning
                                enabled: true,

                                // Panning directions. Remove the appropriate direction to disable 
                                // Eg. 'y' would only allow panning in the y direction
                                mode: 'x'
                            },

                            // Container for zoom options
                            zoom: {
                                // Boolean to enable zooming
                                enabled: true,

                                // Zooming directions. Remove the appropriate direction to disable 
                                // Eg. 'y' would only allow zooming in the y direction
                                mode: 'x',
                                speed: 1000,
                            }
                        }
                    }
                }
            });
        }
        ).catch(error => console.log(error));
}
</script>
<template>
	<div class="content">
        <div class="input">
            <input type="text" id="cityname" placeholder="Cityname" v-model="cityname">
            <button id="submit" v-on:click="getCoordinates(cityname)">Submit</button>
        </div>
         <div class="chart">
            <h3>Daily stats 1960-2021</h3>
            <canvas id="myChart"></canvas>
        </div>
    </div>
</template>

<style>
.content {
    grid-area: content;
    background-color: #fff;
    padding: 10px;
    border-radius: 5px;
    box-shadow: 0px 0px 5px 0px rgba(0,0,0,0.75);
}

.input {
    display: grid;
    grid-template-columns: 1fr auto;
    grid-template-rows: auto;
    grid-template-areas:
        "input button";
    grid-gap: 10px;
}

.input input {
    grid-area: input;
    padding: 10px;
    border-radius: 5px;
    border: 1px solid #ccc;

}

.input button {
    grid-area: button;
    padding: 10px;
    border-radius: 5px;
    border: 1px solid #ccc;
    background-color: #fff;
    cursor: pointer;
}

.chart {
    padding: 10px;
}
</style>