# Actividad 3 — Histórico local Smart-Environment IoT

## Integración

La aplicación Flutter conserva los módulos anteriores y muestra **Historial IoT**
desde su pantalla principal. En `HistoricalAlertsScreen` hay tres pestañas:

1. **Lecturas:** `FutureBuilder<List<SensorReading>>` + `ListView.builder` con
   estados de carga, error y sin datos, y resaltado rojo cuando
   temperatura > umbral guardado.
2. **Alertas:** `FutureBuilder<List<AlertaNodo>>` + `ListView.builder`
   con colores, iconos, nodo, timestamp y umbral utilizado al momento del evento.
3. **ESP32:** consulta HTTP cada 5 s o manualmente; transforma JSON en lecturas
   y registra lecturas/alertas en SQLite sin bloquear la UI.

La lectura SQLite con `sqflite` se ejecuta de manera asíncrona mediante el
plugin de base de datos; `FutureBuilder` no crea un isolate Dart explícito.
El motor nativo de SQLite gestiona sus operaciones fuera del dibujado de UI.
Al salir de la pestaña se detiene el polling.

### Contrato del ESP32

El ESP32 debe estar accesible desde el móvil, por la misma Wi-Fi o en modo AP.
En el firmware debe existir una ruta HTTP GET, por ejemplo
`http://192.168.4.1/reading`, con una respuesta 200 y este cuerpo:

```json
{
  "nodeId": "ESP32_01",
  "location": "Invernadero A",
  "temperature": 36.8,
  "humidity": 62.5
}
```

Puede enviar sólo uno de los dos sensores. También se admiten los nombres
`node_id`, `temperatura` y `humedad`. No se fabrican valores cuando el
equipo no responde: la pantalla muestra el error de conexión.

**Regla:** si `temperature > temperatureThreshold` (por defecto **35 °C**)
se guardan la lectura y una alerta vinculada al nodo y a la lectura. Una
temperatura igual al umbral no crea una alerta. Se guarda en la alerta el
umbral de ese evento, aunque luego se configure uno diferente.

La base usa migración **v2 → v3**: agrega `nodo_id` y `umbral` a
`readings`, y `umbral` y `lectura_id` a `alertas`. No elimina filas
anteriores. Una transacción SQLite registra todas las lecturas de cada
respuesta y su alerta correspondiente. Los datos antiguos mantienen
`nodo_id = NULL` y usan 35 °C para la clasificación visual.

### Ejecución de la práctica

1. Instalar Flutter/Dart y ejecutar `flutter pub get`.
2. Ejecutar `flutter test` y `flutter analyze`.
3. Instalar la app en Android con `flutter run`. En el teléfono abrir
   **Historial IoT → ESP32**.
4. Conectar el teléfono al Wi-Fi del ESP32, modificar la URL si hace falta y
   configurar el umbral. Pulsar **Leer una vez** o **Monitorear cada 5 s**.
5. Probar respuestas con temperatura **34.9**, **35.0**, **35.1** y **40.0** °C.
   Sólo 35.1 y 40.0 deben aparecer en **Alertas** con el umbral 35.
   Verificar que también se ven todas en **Lecturas** y que permanecen al
   reiniciar la app.

La aplicación Android declara permiso INTERNET y permite HTTP sin cifrar
para usar el ESP32 en una red local de laboratorio. En producción, usar HTTPS
y restringir el tráfico inseguro. El polling sólo funciona con la pantalla
activa; **no** constituye recolección en segundo plano. El acceso HTTP desde
Flutter Web requiere configurar CORS en el ESP32, y `sqflite` es SQLite
nativo para Android/iOS, no una implementación de SQLite Web.

### Evidencia esperada para evaluación

Captura del panel ESP32 conectado con temperatura >35, captura de **Lecturas**
con estado crítico, captura de **Alertas** con evento registrado, y ejecución
de `flutter test` con los casos de umbral, HTTP y persistencia.

**Nota:** el hardware y su firmware no están incluidos en este repositorio,
por lo que la conexión física con el ESP32 requiere una prueba en dispositivo
real. No se presenta una simulación como evidencia de conexión.
