<div align="center">

# 🔌 Sistemas Embebidos

**Código y reportes de prácticas con FPGA**

![Verilog](https://img.shields.io/badge/HDL-Verilog-1f6feb?style=for-the-badge)
![FPGA](https://img.shields.io/badge/FPGA-DE10--Lite-00979d?style=for-the-badge)
![Quartus](https://img.shields.io/badge/Quartus-Prime%20Lite-0071c5?style=for-the-badge)
![Prácticas](https://img.shields.io/badge/Pr%C3%A1cticas-4-2da44e?style=for-the-badge)

🎓 **Universidad de las Américas Puebla (UDLAP)**
Departamento de Computación, Electrónica y Mecatrónica

</div>

---

## 👥 Equipo

| Integrante |
|---|
| 🧑‍💻 Miguel Ángel Sarmiento Luna |
| 🧑‍💻 Juan Diego Acosta Ojeda |

## 🛠️ Plataforma y herramientas

| | Herramienta | Uso |
|:--:|---|---|
| 🧩 | **Terasic DE10-Lite** | Tarjeta FPGA (interruptores, botones, LEDs y displays de 7 segmentos) |
| 📝 | **Verilog** | Descripción del hardware |
| 🧪 | **Active-HDL** | Compilación y simulación |
| ⚙️ | **Quartus Prime Lite** | Síntesis, asignación de pines y programación |

```mermaid
flowchart LR
    A[Verilog] --> B[Active-HDL<br/>simulación] --> C[Quartus Prime<br/>síntesis y pines] --> D[(DE10-Lite<br/>FPGA)]
```

## 📚 Prácticas

Cada carpeta contiene el código Verilog y, en su propio `README.md`, el reporte correspondiente.

| # | Práctica | Descripción | Reporte |
|:--:|---|---|:--:|
| 1️⃣ | **Sumadores** | Half/full adder, sumadores de 4 y 16 bits y display de 7 segmentos | [📄 Ver](Practica1/) |
| 2️⃣ | **ALU de 5 bits** | Suma, resta y multiplicación con signo y despliegue decimal | [📄 Ver](Practica2/) |
| 3️⃣ | **Contador con signo** | Contador de 9 bits controlado con botones y displays | [📄 Ver](Practica3/) |
| 4️⃣ | **UART** | Transmisor y receptor serial en la DE10-Lite | [📄 Ver](Practica4/) |

## 📝 Formato de los reportes

Todos los reportes siguen las mismas secciones:

| | Sección | | Sección |
|:--:|---|:--:|---|
| 1 | Resumen | 5 | Análisis de resultados |
| 2 | Objetivos | 6 | Cuestionario |
| 3 | Marco teórico | 7 | Conclusión |
| 4 | Planteamiento del experimento | 8 | Referencias |

---

<div align="center">
<sub>Sistemas Embebidos · UDLAP</sub>
</div>
