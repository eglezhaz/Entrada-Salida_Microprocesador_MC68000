# Proyecto de E/S por Interrupciones (MC68000 / MC68681)

Este repositorio contiene la implementación de un sistema de Entrada/Salida (E/S) gestionado mediante interrupciones para el microprocesador **Motorola MC68000** y el controlador de comunicaciones serie **DUART MC68681**.

El proyecto fue desarrollado en lenguaje **Ensamblador (Assembly 68k)** y diseñado para ejecutarse sobre el entorno de simulación **BSVC**.

## 📋 Descripción del Proyecto

El objetivo principal es gestionar la comunicación serie asíncrona a través de dos líneas (Línea A y Línea B) de manera **no bloqueante**. A diferencia de la E/S por sondeo (polling), este sistema permite que el procesador continúe ejecutando instrucciones mientras la DUART gestiona la recepción y transmisión de caracteres en segundo plano, interrumpiendo a la CPU solo cuando es necesario.

### Características Técnicas

* **Arquitectura:** Microprocesador CISC MC68000.
* **Controlador:** DUART MC68681 (Dual Universal Asynchronous Receiver/Transmitter).
* **Mecanismo:** Gestión pura por interrupciones (Vector de interrupción `0x40`).
* **Estructuras de Datos:** Implementación de **Buffers Circulares (FIFO)** de 2000 bytes para la gestión de colas de transmisión y recepción internas.
* **Comunicación:** Full-Duplex a 38400 bps (8 bits, sin paridad).

## 🛠️ Estructura del Software

El núcleo del proyecto se basa en las siguientes subrutinas implementadas:

### 1. `INIT` (Inicialización)
Configura la DUART para operar a **38400 bps**, define el formato de trama, habilita las interrupciones vectorizadas y prepara los buffers internos mediante `INI_BUFS`.

### 2. `SCAN` (Lectura No Bloqueante)
Solicita la lectura de `N` caracteres de una línea específica (A o B).
* Extrae caracteres del buffer interno de recepción utilizando la rutina auxiliar `LEECAR`.
* No bloquea el procesador esperando hardware; si hay datos, los devuelve; si no, retorna lo disponible.

### 3. `PRINT` (Escritura No Bloqueante)
Solicita la escritura de caracteres en una línea.
* Escribe los datos en el buffer interno de transmisión mediante `ESCCAR`.
* Activa las interrupciones de transmisión de la DUART para que la `RTI` envíe los datos automáticamente en segundo plano.

### 4. `RTI` (Rutina de Tratamiento de Interrupción)
El motor del sistema. Se ejecuta automáticamente cuando la DUART genera una interrupción en el vector `0x40`.
* **Recepción:** Detecta la llegada de un dato y lo guarda en el buffer circular correspondiente (si no está lleno).
* **Transmisión:** Detecta que la línea está libre y envía el siguiente dato de la cola de salida.

## 🚀 Requisitos y Ejecución

Para ejecutar este proyecto se requiere el entorno de simulación **BSVC** configurado para la arquitectura M68k.

### Dependencias
* **Ensamblador:** `68kasm`
* **Simulador:** `bsvc` (Bradford W. Mott)

### Compilación y Ejecución
1.  Ensamblar el código fuente para generar el objeto y el listado:
    ```bash
    68kasm -l es_int.s
    ```
    *(Esto generará `es_int.h68` y `es_int.lis`)*

2.  Cargar el entorno en el simulador:
    ```bash
    bsvc practica.setup
    ```

3.  Desde la interfaz de BSVC, cargar el programa objeto (`.h68`) y ejecutar.

## 📚 Referencias

Este proyecto sigue las especificaciones del mapa de memoria y registros de control definidos para la DUART MC68681 (MR1, MR2, SR, CSR, CR, IMR, ISR) y el modelo de programación del MC68000.

---
*Proyecto realizado para la asignatura de Arquitectura de Computadores / Estructura de Computadores.*
