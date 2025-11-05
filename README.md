# Battery_Thermal_Management_System

A Battery Thermal Management System regulates the temperature of battery cells during charging, discharging, and resting. The goal is to keep the battery temperature between 20°C and 40°C (typically), since too high or too low temperatures can degrade performance or damage cells.

Thermal model — governing equations (lumped two-mass model)

I use two lumped thermal masses

Cell temperature 
𝑇𝑐
(
𝑡
)
(t) (K) with mass 
𝑚
𝑐
 and heat capacity 
𝑐𝑝
,
𝑐

Coolant temperature 
𝑇ℓ
(
𝑡
)
(t) (K) with mass 
𝑚
ℓ
 and heat capacity 
𝑐
𝑝
,
ℓ

Heat generation inside the cell (instantaneous, 
𝑄
˙
𝑔
𝑒
𝑛
in W) can be modeled in two ways:

1) Resistive dissipation

  Q˙​gen​ = I2Rint​ (where 
𝐼 is cell current (A), Rint nternal resistance (Ω).

2) Voltage based

   Q˙​gen​ = I(V−VOC​)
   
Heat flow from cell to coolant (convection/conduction lumped) is modeled as

Q˙​c→ℓ ​= hAu(t)(Tc​−Tℓ​)
ℎ
𝐴
 is the maximal overall thermal conductance (W/K),

𝑢
(
𝑡
)
∈
[
0
,
1
]
u(t)∈[0,1] is controller cooling fraction (pump/fan duty)

Coolant loses heat to ambient

Q˙​ℓ→a ​= hrad​(Tℓ​−Tamb​)

where 
ℎ
rad
is a lumped radiator conductance (W/K).

Energy balances

Cell
mc ​cp,c dTc/​dt ​​= Q˙​gen​ − Q˙​c→ℓ​ = Q˙​gen ​− hAu(Tc​−Tℓ​)

Coolant
mℓ​cp,ℓ​ dTℓ/dt ​​= Q˙​c→ℓ​ − Q˙​ℓ→a ​= hAu(Tc​−Tℓ​) − hrad​(Tℓ​−Tamb​)



Steady-state algebra(solve for  T
c
,T
ℓ when 
𝑑/
𝑑
𝑡 =
0)

Set time derivatives to zero

1) Q˙​gen​ = hAu(Tc​−Tℓ​)
2) hAu(Tc​−Tℓ​) = hrad​(Tℓ​−Tamb​)
   
From (1) and (2)
Q˙​gen​ = hrad​(Tℓ​−Tamb​) ⟹ Tℓ​ = Tamb​ + hrad​Q˙​gen​​

from (1)
Tc​ = Tℓ ​+ hAuQ˙​gen ​​= Tamb​ + hrad​Q˙​gen​​ + hAuQ˙​gen​​

To find the cooling fraction 
𝑢
u required to keep 
𝑇
𝑐
at a desired setpoint 
𝑇
set
, solve:

T
set
=T
amb
+
Q
.
gen/
h
rad
+
Q
˙
gen/
hAu

Rearragnge

Q˙​gen​​/hAu = Tset ​− Tamb ​− Q˙​gen/​​hrad

if the right side is positive


u = Q˙​gen​​ / hA(Tset​−Tamb​−hrad​Q˙​gen​​)

If the denominator 
Tset​−Tamb ​− Q˙​gen​ / hrad​ ≤ 0 then no positive 𝑢 0..1) can achieve the setpoint — i.e. even full cooling u = 1 cannot cool the cell to Tset In that case you need a larger hA, larger radiator conductance hrad, lower ambient, or reduced heat generation.

Graph (1) Temperature Response of Cell and Coolant

Graph:
Plots battery cell temperature (blue) and coolant temperature (orange dashed) vs. time, along with the temperature setpoint (red dashed line).

Explanation:

At the start, both the cell and coolant are at 25 °C, the same as ambient. When discharge begins (40 A), internal heat generation Qge n​= I^2Rint increases cell temperature.The controller senses that the cell is above the setpoint (30 °C) and activates cooling. The coolant temperature rises more slowly because of its higher heat capacity, acting as a thermal buffer. When the current stops (rest phase, 200–400 s), no new heat is generated — the temperatures drop gradually toward ambient. During heavy discharge (80 A) from 400–700 s, heat generation sharply increases; the cell temperature climbs rapidly, and the controller output reaches near maximum cooling (100%). When charging starts (−20 A), internal heating is smaller, and both cell and coolant temperatures fall again.

Graph (2): Battery Current Profile

Graph:
Shows the applied battery current vs. time:

Positive current = discharging (power output)

Zero = idle

Negative = charging

Explanation:

0–200 s: 40 A discharge → moderate heat generation

200–400 s: rest (0 A) → no heat

400–700 s: 80 A heavy discharge → high heat generation → strongest temperature rise

700–900 s: −20 A charge → small heat, gradual cooling

Graph (3): PI Controller Output (Cooling Effort)

Explanation:

At startup (low temperature), the controller output 
𝑢 ≈ 0 → no cooling needed.

When temperature exceeds the setpoint, 
𝑢 rises proportionally (Kp term) and continues increasing if the error persists (Ki term).

During the 80 A discharge, 
𝑢 quickly climbs to 100%, indicating maximum cooling effort.

As the cell cools down, 
𝑢 decreases back toward 0.   
