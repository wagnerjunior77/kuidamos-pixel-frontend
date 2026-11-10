/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : X-2025.06-SP2
// Date      : Mon Nov  9 00:30:46 2026
/////////////////////////////////////////////////////////////


module grayscale_core ( pixel_r, pixel_g, pixel_b, y_gray );
  input [7:0] pixel_r;
  input [7:0] pixel_g;
  input [7:0] pixel_b;
  output [7:0] y_gray;
  wire   intadd_2_A_9_, intadd_2_A_5_, intadd_2_A_4_, intadd_2_A_3_,
         intadd_2_A_2_, intadd_2_B_8_, intadd_2_B_7_, intadd_2_B_6_,
         intadd_2_B_5_, intadd_2_B_4_, intadd_2_B_3_, intadd_2_B_2_,
         intadd_2_B_1_, intadd_2_SUM_4_, intadd_2_SUM_3_, intadd_2_SUM_2_,
         intadd_2_SUM_1_, intadd_2_SUM_0_, intadd_2_n10, intadd_2_n9,
         intadd_2_n8, intadd_2_n7, intadd_2_n6, intadd_2_n5, intadd_2_n4,
         intadd_2_n3, intadd_2_n2, intadd_2_n1, intadd_3_A_4_, intadd_3_A_3_,
         intadd_3_A_2_, intadd_3_B_4_, intadd_3_B_3_, intadd_3_B_2_,
         intadd_3_B_1_, intadd_3_CI, intadd_3_SUM_3_, intadd_3_SUM_0_,
         intadd_3_n5, intadd_3_n4, intadd_3_n3, intadd_3_n2, intadd_3_n1,
         intadd_4_A_4_, intadd_4_A_3_, intadd_4_A_2_, intadd_4_A_1_,
         intadd_4_B_3_, intadd_4_B_2_, intadd_4_SUM_2_, intadd_4_SUM_1_,
         intadd_4_SUM_0_, intadd_4_n5, intadd_4_n4, intadd_4_n3, intadd_4_n2,
         intadd_4_n1, intadd_5_A_3_, intadd_5_A_2_, intadd_5_A_1_,
         intadd_5_B_3_, intadd_5_B_2_, intadd_5_B_1_, intadd_5_CI, intadd_5_n4,
         intadd_5_n3, intadd_5_n2, intadd_5_n1, intadd_6_A_3_, intadd_6_A_2_,
         intadd_6_A_1_, intadd_6_B_3_, intadd_6_B_2_, intadd_6_B_1_,
         intadd_6_B_0_, intadd_6_CI, intadd_6_SUM_3_, intadd_6_SUM_2_,
         intadd_6_SUM_1_, intadd_6_SUM_0_, intadd_6_n4, intadd_6_n3,
         intadd_6_n2, intadd_6_n1, intadd_7_A_2_, intadd_7_A_1_, intadd_7_B_2_,
         intadd_7_B_1_, intadd_7_n3, intadd_7_n2, intadd_7_n1, intadd_8_A_1_,
         intadd_8_A_0_, intadd_8_B_0_, intadd_8_SUM_2_, intadd_8_SUM_1_,
         intadd_8_SUM_0_, intadd_8_n3, intadd_8_n2, intadd_8_n1, intadd_9_A_2_,
         intadd_9_A_1_, intadd_9_B_2_, intadd_9_B_1_, intadd_9_B_0_,
         intadd_9_CI, intadd_9_SUM_1_, intadd_9_SUM_0_, intadd_9_n3,
         intadd_9_n2, intadd_9_n1, intadd_10_A_2_, intadd_10_B_2_,
         intadd_10_B_1_, intadd_10_SUM_2_, intadd_10_SUM_1_, intadd_10_SUM_0_,
         intadd_10_n3, intadd_10_n2, intadd_10_n1, intadd_11_A_2_,
         intadd_11_A_1_, intadd_11_B_2_, intadd_11_B_1_, intadd_11_SUM_2_,
         intadd_11_SUM_0_, intadd_11_n3, intadd_11_n2, intadd_11_n1, n1, n2,
         n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17,
         n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30, n31,
         n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42, n43, n44, n45,
         n46, n47, n48, n49, n50, n51, n52, n53, n54, n55, n56, n57, n58, n59,
         n60, n61, n62, n63, n64, n65, n66, n67, n68, n69, n70, n71, n72, n73,
         n74, n75, n76, n77, n78, n79, n80, n81, n82, n83;

  FADDX1_RVT intadd_2_U11 ( .A(pixel_r[3]), .B(pixel_r[2]), .CI(pixel_b[5]), 
        .CO(intadd_2_n10), .S(intadd_2_SUM_0_) );
  FADDX1_RVT intadd_2_U10 ( .A(intadd_2_B_1_), .B(pixel_g[2]), .CI(
        intadd_2_n10), .CO(intadd_2_n9), .S(intadd_2_SUM_1_) );
  FADDX1_RVT intadd_2_U9 ( .A(intadd_2_B_2_), .B(intadd_2_A_2_), .CI(
        intadd_2_n9), .CO(intadd_2_n8), .S(intadd_2_SUM_2_) );
  FADDX1_RVT intadd_2_U8 ( .A(intadd_2_B_3_), .B(intadd_2_A_3_), .CI(
        intadd_2_n8), .CO(intadd_2_n7), .S(intadd_2_SUM_3_) );
  FADDX1_RVT intadd_2_U7 ( .A(intadd_2_B_4_), .B(intadd_2_A_4_), .CI(
        intadd_2_n7), .CO(intadd_2_n6), .S(intadd_2_SUM_4_) );
  FADDX1_RVT intadd_2_U6 ( .A(intadd_2_B_5_), .B(intadd_2_A_5_), .CI(
        intadd_2_n6), .CO(intadd_2_n5), .S(y_gray[2]) );
  FADDX1_RVT intadd_2_U5 ( .A(intadd_2_B_6_), .B(intadd_4_n1), .CI(intadd_2_n5), .CO(intadd_2_n4), .S(y_gray[3]) );
  FADDX1_RVT intadd_2_U4 ( .A(intadd_2_B_7_), .B(intadd_3_n1), .CI(intadd_2_n4), .CO(intadd_2_n3), .S(y_gray[4]) );
  FADDX1_RVT intadd_2_U3 ( .A(intadd_2_B_8_), .B(intadd_5_n1), .CI(intadd_2_n3), .CO(intadd_2_n2), .S(y_gray[5]) );
  FADDX1_RVT intadd_2_U2 ( .A(intadd_7_n1), .B(intadd_2_A_9_), .CI(intadd_2_n2), .CO(intadd_2_n1), .S(y_gray[6]) );
  FADDX1_RVT intadd_3_U6 ( .A(pixel_g[5]), .B(pixel_b[2]), .CI(intadd_3_CI), 
        .CO(intadd_3_n5), .S(intadd_3_SUM_0_) );
  FADDX1_RVT intadd_3_U5 ( .A(intadd_3_B_1_), .B(pixel_g[1]), .CI(intadd_3_n5), 
        .CO(intadd_3_n4), .S(intadd_2_A_3_) );
  FADDX1_RVT intadd_3_U4 ( .A(intadd_3_B_2_), .B(intadd_3_A_2_), .CI(
        intadd_3_n4), .CO(intadd_3_n3), .S(intadd_2_B_4_) );
  FADDX1_RVT intadd_3_U3 ( .A(intadd_3_B_3_), .B(intadd_3_A_3_), .CI(
        intadd_3_n3), .CO(intadd_3_n2), .S(intadd_3_SUM_3_) );
  FADDX1_RVT intadd_3_U2 ( .A(intadd_3_B_4_), .B(intadd_3_A_4_), .CI(
        intadd_3_n2), .CO(intadd_3_n1), .S(intadd_2_B_6_) );
  FADDX1_RVT intadd_4_U6 ( .A(pixel_r[3]), .B(pixel_r[0]), .CI(pixel_b[6]), 
        .CO(intadd_4_n5), .S(intadd_4_SUM_0_) );
  FADDX1_RVT intadd_4_U5 ( .A(intadd_3_SUM_0_), .B(intadd_4_A_1_), .CI(
        intadd_4_n5), .CO(intadd_4_n4), .S(intadd_4_SUM_1_) );
  FADDX1_RVT intadd_4_U4 ( .A(intadd_4_B_2_), .B(intadd_4_A_2_), .CI(
        intadd_4_n4), .CO(intadd_4_n3), .S(intadd_4_SUM_2_) );
  FADDX1_RVT intadd_4_U3 ( .A(intadd_4_B_3_), .B(intadd_4_A_3_), .CI(
        intadd_4_n3), .CO(intadd_4_n2), .S(intadd_2_A_4_) );
  FADDX1_RVT intadd_4_U2 ( .A(intadd_3_SUM_3_), .B(intadd_4_A_4_), .CI(
        intadd_4_n2), .CO(intadd_4_n1), .S(intadd_2_B_5_) );
  FADDX1_RVT intadd_5_U5 ( .A(pixel_g[5]), .B(pixel_g[2]), .CI(intadd_5_CI), 
        .CO(intadd_5_n4), .S(intadd_3_B_2_) );
  FADDX1_RVT intadd_5_U4 ( .A(intadd_5_B_1_), .B(intadd_5_A_1_), .CI(
        intadd_5_n4), .CO(intadd_5_n3), .S(intadd_4_A_4_) );
  FADDX1_RVT intadd_5_U3 ( .A(intadd_5_B_2_), .B(intadd_5_A_2_), .CI(
        intadd_5_n3), .CO(intadd_5_n2), .S(intadd_3_A_4_) );
  FADDX1_RVT intadd_5_U2 ( .A(intadd_5_B_3_), .B(intadd_5_A_3_), .CI(
        intadd_5_n2), .CO(intadd_5_n1), .S(intadd_2_B_7_) );
  FADDX1_RVT intadd_6_U5 ( .A(intadd_6_B_0_), .B(pixel_b[1]), .CI(intadd_6_CI), 
        .CO(intadd_6_n4), .S(intadd_6_SUM_0_) );
  FADDX1_RVT intadd_6_U4 ( .A(intadd_6_B_1_), .B(intadd_6_A_1_), .CI(
        intadd_6_n4), .CO(intadd_6_n3), .S(intadd_6_SUM_1_) );
  FADDX1_RVT intadd_6_U3 ( .A(intadd_6_B_2_), .B(intadd_6_A_2_), .CI(
        intadd_6_n3), .CO(intadd_6_n2), .S(intadd_6_SUM_2_) );
  FADDX1_RVT intadd_6_U2 ( .A(intadd_6_B_3_), .B(intadd_6_A_3_), .CI(
        intadd_6_n2), .CO(intadd_6_n1), .S(intadd_6_SUM_3_) );
  FADDX1_RVT intadd_7_U4 ( .A(pixel_b[6]), .B(pixel_r[5]), .CI(pixel_g[7]), 
        .CO(intadd_7_n3), .S(intadd_5_B_2_) );
  FADDX1_RVT intadd_7_U3 ( .A(intadd_7_B_1_), .B(intadd_7_A_1_), .CI(
        intadd_7_n3), .CO(intadd_7_n2), .S(intadd_5_B_3_) );
  FADDX1_RVT intadd_7_U2 ( .A(intadd_7_B_2_), .B(intadd_7_A_2_), .CI(
        intadd_7_n2), .CO(intadd_7_n1), .S(intadd_2_B_8_) );
  FADDX1_RVT intadd_8_U4 ( .A(intadd_8_B_0_), .B(intadd_8_A_0_), .CI(
        intadd_4_SUM_0_), .CO(intadd_8_n3), .S(intadd_8_SUM_0_) );
  FADDX1_RVT intadd_8_U3 ( .A(intadd_4_SUM_1_), .B(intadd_8_A_1_), .CI(
        intadd_8_n3), .CO(intadd_8_n2), .S(intadd_8_SUM_1_) );
  FADDX1_RVT intadd_8_U2 ( .A(intadd_4_SUM_2_), .B(intadd_2_SUM_3_), .CI(
        intadd_8_n2), .CO(intadd_8_n1), .S(intadd_8_SUM_2_) );
  FADDX1_RVT intadd_9_U4 ( .A(intadd_9_B_0_), .B(pixel_b[2]), .CI(intadd_9_CI), 
        .CO(intadd_9_n3), .S(intadd_9_SUM_0_) );
  FADDX1_RVT intadd_9_U3 ( .A(intadd_9_B_1_), .B(intadd_9_A_1_), .CI(
        intadd_9_n3), .CO(intadd_9_n2), .S(intadd_9_SUM_1_) );
  FADDX1_RVT intadd_9_U2 ( .A(intadd_9_B_2_), .B(intadd_9_A_2_), .CI(
        intadd_9_n2), .CO(intadd_9_n1), .S(intadd_6_A_3_) );
  FADDX1_RVT intadd_10_U4 ( .A(pixel_g[0]), .B(pixel_r[0]), .CI(pixel_r[2]), 
        .CO(intadd_10_n3), .S(intadd_10_SUM_0_) );
  FADDX1_RVT intadd_10_U3 ( .A(intadd_10_B_1_), .B(pixel_g[1]), .CI(
        intadd_10_n3), .CO(intadd_10_n2), .S(intadd_10_SUM_1_) );
  FADDX1_RVT intadd_10_U2 ( .A(intadd_10_B_2_), .B(intadd_10_A_2_), .CI(
        intadd_10_n2), .CO(intadd_10_n1), .S(intadd_10_SUM_2_) );
  FADDX1_RVT intadd_11_U4 ( .A(pixel_r[3]), .B(pixel_r[1]), .CI(pixel_g[2]), 
        .CO(intadd_11_n3), .S(intadd_11_SUM_0_) );
  FADDX1_RVT intadd_11_U3 ( .A(intadd_11_B_1_), .B(intadd_11_A_1_), .CI(
        intadd_11_n3), .CO(intadd_11_n2), .S(intadd_10_A_2_) );
  FADDX1_RVT intadd_11_U2 ( .A(intadd_11_B_2_), .B(intadd_11_A_2_), .CI(
        intadd_11_n2), .CO(intadd_11_n1), .S(intadd_11_SUM_2_) );
  INVX0_RVT U3 ( .A(pixel_g[0]), .Y(intadd_6_A_1_) );
  AND2X1_RVT U4 ( .A1(pixel_b[1]), .A2(pixel_g[0]), .Y(n6) );
  INVX0_RVT U5 ( .A(pixel_b[2]), .Y(n79) );
  INVX0_RVT U6 ( .A(pixel_b[0]), .Y(n82) );
  AO22X1_RVT U7 ( .A1(pixel_b[0]), .A2(n79), .A3(n82), .A4(pixel_b[2]), .Y(n5)
         );
  INVX0_RVT U8 ( .A(intadd_6_SUM_0_), .Y(n1) );
  FADDX1_RVT U9 ( .A(intadd_11_SUM_0_), .B(n2), .CI(n1), .CO(n12), .S(n10) );
  INVX0_RVT U10 ( .A(pixel_b[1]), .Y(n30) );
  AO22X1_RVT U11 ( .A1(pixel_b[1]), .A2(intadd_6_A_1_), .A3(n30), .A4(
        pixel_g[0]), .Y(n4) );
  OA21X1_RVT U12 ( .A1(pixel_r[1]), .A2(n4), .A3(pixel_b[0]), .Y(n3) );
  AO22X1_RVT U13 ( .A1(pixel_r[1]), .A2(n4), .A3(pixel_r[0]), .A4(n3), .Y(n8)
         );
  FADDX1_RVT U14 ( .A(pixel_g[1]), .B(n6), .CI(n5), .CO(n2), .S(n7) );
  AO222X1_RVT U15 ( .A1(n8), .A2(n7), .A3(n8), .A4(intadd_10_SUM_0_), .A5(n7), 
        .A6(intadd_10_SUM_0_), .Y(n9) );
  AO222X1_RVT U16 ( .A1(n10), .A2(intadd_10_SUM_1_), .A3(n10), .A4(n9), .A5(
        intadd_10_SUM_1_), .A6(n9), .Y(n11) );
  AO222X1_RVT U17 ( .A1(n12), .A2(intadd_10_SUM_2_), .A3(n12), .A4(n11), .A5(
        intadd_10_SUM_2_), .A6(n11), .Y(n13) );
  AOI222X1_RVT U18 ( .A1(intadd_10_n1), .A2(intadd_11_SUM_2_), .A3(
        intadd_10_n1), .A4(n13), .A5(intadd_11_SUM_2_), .A6(n13), .Y(n15) );
  INVX0_RVT U19 ( .A(intadd_11_n1), .Y(n14) );
  AO222X1_RVT U20 ( .A1(n15), .A2(intadd_6_SUM_3_), .A3(n15), .A4(n14), .A5(
        intadd_6_SUM_3_), .A6(n14), .Y(n17) );
  FADDX1_RVT U21 ( .A(intadd_9_n1), .B(intadd_2_SUM_2_), .CI(intadd_8_SUM_1_), 
        .S(n16) );
  AO222X1_RVT U22 ( .A1(n17), .A2(intadd_6_n1), .A3(n17), .A4(n16), .A5(
        intadd_6_n1), .A6(n16), .Y(n22) );
  INVX0_RVT U23 ( .A(intadd_9_n1), .Y(n18) );
  OAI222X1_RVT U24 ( .A1(n18), .A2(intadd_2_SUM_2_), .A3(n18), .A4(
        intadd_8_SUM_1_), .A5(intadd_2_SUM_2_), .A6(intadd_8_SUM_1_), .Y(n21)
         );
  INVX0_RVT U25 ( .A(intadd_8_SUM_2_), .Y(n20) );
  INVX0_RVT U26 ( .A(n19), .Y(y_gray[0]) );
  INVX0_RVT U27 ( .A(intadd_2_SUM_4_), .Y(n27) );
  INVX0_RVT U28 ( .A(intadd_8_n1), .Y(n26) );
  FADDX1_RVT U29 ( .A(n22), .B(n21), .CI(n20), .CO(n25), .S(n19) );
  INVX0_RVT U30 ( .A(n23), .Y(y_gray[1]) );
  INVX0_RVT U31 ( .A(pixel_b[7]), .Y(intadd_7_A_1_) );
  INVX0_RVT U32 ( .A(pixel_r[7]), .Y(n61) );
  INVX0_RVT U33 ( .A(pixel_g[6]), .Y(n64) );
  NAND2X0_RVT U34 ( .A1(n61), .A2(n64), .Y(n70) );
  INVX0_RVT U35 ( .A(pixel_g[7]), .Y(n51) );
  NAND2X0_RVT U36 ( .A1(pixel_r[7]), .A2(pixel_g[6]), .Y(n68) );
  AOI222X1_RVT U37 ( .A1(intadd_7_A_1_), .A2(n70), .A3(pixel_b[7]), .A4(n51), 
        .A5(pixel_g[7]), .A6(n68), .Y(n24) );
  XOR2X1_RVT U38 ( .A1(intadd_2_n1), .A2(n24), .Y(y_gray[7]) );
  FADDX1_RVT U39 ( .A(n27), .B(n26), .CI(n25), .CO(n28), .S(n23) );
  INVX0_RVT U40 ( .A(n28), .Y(intadd_2_A_5_) );
  INVX0_RVT U41 ( .A(intadd_2_SUM_1_), .Y(intadd_9_B_2_) );
  INVX0_RVT U42 ( .A(intadd_8_SUM_0_), .Y(intadd_6_B_3_) );
  INVX0_RVT U43 ( .A(intadd_6_SUM_2_), .Y(intadd_11_A_2_) );
  INVX0_RVT U44 ( .A(intadd_2_SUM_0_), .Y(intadd_6_B_2_) );
  INVX0_RVT U45 ( .A(intadd_9_SUM_1_), .Y(intadd_11_B_2_) );
  INVX0_RVT U46 ( .A(pixel_g[3]), .Y(n81) );
  INVX0_RVT U47 ( .A(pixel_r[4]), .Y(n56) );
  INVX0_RVT U48 ( .A(pixel_r[2]), .Y(n72) );
  AO222X1_RVT U49 ( .A1(n81), .A2(n56), .A3(n81), .A4(n72), .A5(n56), .A6(n72), 
        .Y(intadd_9_A_1_) );
  INVX0_RVT U50 ( .A(intadd_9_SUM_0_), .Y(intadd_11_B_1_) );
  INVX0_RVT U51 ( .A(pixel_r[1]), .Y(intadd_9_B_0_) );
  INVX0_RVT U52 ( .A(intadd_6_SUM_1_), .Y(intadd_10_B_2_) );
  INVX0_RVT U53 ( .A(pixel_r[0]), .Y(intadd_6_B_0_) );
  INVX0_RVT U54 ( .A(pixel_g[2]), .Y(intadd_6_B_1_) );
  INVX0_RVT U55 ( .A(pixel_g[4]), .Y(n48) );
  INVX0_RVT U56 ( .A(n29), .Y(intadd_8_B_0_) );
  FADDX1_RVT U57 ( .A(n30), .B(pixel_b[4]), .CI(n48), .CO(n33), .S(n29) );
  INVX0_RVT U58 ( .A(n31), .Y(intadd_8_A_1_) );
  INVX0_RVT U59 ( .A(n32), .Y(intadd_2_B_1_) );
  FADDX1_RVT U60 ( .A(intadd_6_A_1_), .B(n81), .CI(n33), .CO(n34), .S(n31) );
  INVX0_RVT U61 ( .A(n34), .Y(intadd_4_B_2_) );
  INVX0_RVT U62 ( .A(pixel_b[4]), .Y(intadd_9_CI) );
  OR2X1_RVT U63 ( .A1(pixel_g[7]), .A2(pixel_r[6]), .Y(n58) );
  INVX0_RVT U64 ( .A(n58), .Y(n35) );
  NAND2X0_RVT U65 ( .A1(pixel_g[7]), .A2(pixel_r[6]), .Y(n59) );
  OA21X1_RVT U66 ( .A1(n35), .A2(n64), .A3(n59), .Y(n40) );
  INVX0_RVT U67 ( .A(pixel_r[3]), .Y(n42) );
  INVX0_RVT U68 ( .A(pixel_r[5]), .Y(n67) );
  NAND2X0_RVT U69 ( .A1(n67), .A2(n48), .Y(n77) );
  INVX0_RVT U70 ( .A(n77), .Y(n36) );
  NAND2X0_RVT U71 ( .A1(pixel_r[5]), .A2(pixel_g[4]), .Y(n71) );
  OA21X1_RVT U72 ( .A1(n36), .A2(n72), .A3(n71), .Y(n38) );
  INVX0_RVT U73 ( .A(n37), .Y(intadd_4_B_3_) );
  INVX0_RVT U74 ( .A(pixel_b[3]), .Y(intadd_6_CI) );
  FADDX1_RVT U75 ( .A(n40), .B(n39), .CI(n38), .CO(n41), .S(n37) );
  INVX0_RVT U76 ( .A(n41), .Y(intadd_3_A_3_) );
  FADDX1_RVT U77 ( .A(pixel_b[7]), .B(n42), .CI(intadd_9_CI), .CO(n45), .S(n39) );
  INVX0_RVT U78 ( .A(n43), .Y(intadd_3_B_3_) );
  AO222X1_RVT U79 ( .A1(n64), .A2(n81), .A3(n64), .A4(n56), .A5(n81), .A6(n56), 
        .Y(n47) );
  INVX0_RVT U80 ( .A(n44), .Y(intadd_3_B_4_) );
  FADDX1_RVT U81 ( .A(pixel_b[5]), .B(n61), .CI(n45), .CO(n46), .S(n43) );
  INVX0_RVT U82 ( .A(n46), .Y(intadd_5_A_2_) );
  FADDX1_RVT U83 ( .A(n48), .B(pixel_b[5]), .CI(n47), .CO(n49), .S(n44) );
  INVX0_RVT U84 ( .A(n49), .Y(intadd_5_A_3_) );
  INVX0_RVT U85 ( .A(pixel_b[5]), .Y(intadd_3_CI) );
  NAND2X0_RVT U86 ( .A1(intadd_7_A_1_), .A2(n70), .Y(n50) );
  NAND2X0_RVT U87 ( .A1(n50), .A2(n68), .Y(n52) );
  FADDX1_RVT U88 ( .A(pixel_b[7]), .B(n52), .CI(n51), .S(intadd_2_A_9_) );
  OR2X1_RVT U89 ( .A1(pixel_r[6]), .A2(pixel_g[5]), .Y(n65) );
  AO22X1_RVT U90 ( .A1(pixel_r[6]), .A2(pixel_g[5]), .A3(pixel_b[5]), .A4(n65), 
        .Y(intadd_7_A_2_) );
  NAND2X0_RVT U91 ( .A1(pixel_r[6]), .A2(pixel_g[5]), .Y(n53) );
  NAND2X0_RVT U92 ( .A1(n53), .A2(n65), .Y(n83) );
  INVX0_RVT U93 ( .A(n83), .Y(n54) );
  AO22X1_RVT U94 ( .A1(n54), .A2(intadd_3_CI), .A3(n83), .A4(pixel_b[5]), .Y(
        intadd_7_B_1_) );
  NAND2X0_RVT U95 ( .A1(n70), .A2(n68), .Y(n66) );
  INVX0_RVT U96 ( .A(n66), .Y(n55) );
  AO22X1_RVT U97 ( .A1(pixel_b[7]), .A2(n55), .A3(intadd_7_A_1_), .A4(n66), 
        .Y(intadd_7_B_2_) );
  AO22X1_RVT U98 ( .A1(pixel_r[7]), .A2(n58), .A3(pixel_g[7]), .A4(pixel_r[6]), 
        .Y(intadd_5_A_1_) );
  INVX0_RVT U99 ( .A(pixel_b[6]), .Y(n62) );
  AND2X1_RVT U100 ( .A1(pixel_b[3]), .A2(n62), .Y(intadd_5_CI) );
  OA22X1_RVT U101 ( .A1(n81), .A2(pixel_r[4]), .A3(pixel_g[3]), .A4(n56), .Y(
        n57) );
  INVX0_RVT U102 ( .A(n57), .Y(n78) );
  AO22X1_RVT U103 ( .A1(pixel_g[6]), .A2(n57), .A3(n64), .A4(n78), .Y(
        intadd_5_B_1_) );
  NAND2X0_RVT U104 ( .A1(n59), .A2(n58), .Y(n63) );
  INVX0_RVT U105 ( .A(n63), .Y(n60) );
  AO22X1_RVT U106 ( .A1(pixel_r[7]), .A2(n63), .A3(n61), .A4(n60), .Y(
        intadd_3_A_2_) );
  AO22X1_RVT U107 ( .A1(pixel_b[6]), .A2(pixel_b[3]), .A3(n62), .A4(
        intadd_6_CI), .Y(intadd_3_B_1_) );
  HADDX1_RVT U108 ( .A0(n64), .B0(n63), .SO(intadd_4_A_2_) );
  AO22X1_RVT U109 ( .A1(pixel_r[4]), .A2(n65), .A3(pixel_r[6]), .A4(pixel_g[5]), .Y(intadd_4_A_1_) );
  HADDX1_RVT U110 ( .A0(n67), .B0(n66), .SO(intadd_2_A_2_) );
  INVX0_RVT U111 ( .A(n68), .Y(n69) );
  AO21X1_RVT U112 ( .A1(pixel_r[5]), .A2(n70), .A3(n69), .Y(n76) );
  FADDX1_RVT U113 ( .A(pixel_r[1]), .B(pixel_b[7]), .CI(pixel_r[4]), .CO(n75), 
        .S(intadd_2_B_2_) );
  NAND2X0_RVT U114 ( .A1(n71), .A2(n77), .Y(n80) );
  INVX0_RVT U115 ( .A(n80), .Y(n73) );
  AO22X1_RVT U116 ( .A1(n73), .A2(n72), .A3(n80), .A4(pixel_r[2]), .Y(n74) );
  FADDX1_RVT U117 ( .A(n76), .B(n75), .CI(n74), .CO(intadd_4_A_3_), .S(
        intadd_2_B_3_) );
  AO22X1_RVT U118 ( .A1(pixel_g[1]), .A2(n77), .A3(pixel_r[5]), .A4(pixel_g[4]), .Y(intadd_8_A_0_) );
  HADDX1_RVT U119 ( .A0(n78), .B0(pixel_r[2]), .SO(intadd_11_A_1_) );
  NAND2X0_RVT U120 ( .A1(pixel_b[0]), .A2(n79), .Y(intadd_10_B_1_) );
  HADDX1_RVT U121 ( .A0(pixel_g[1]), .B0(n80), .SO(intadd_6_A_2_) );
  FADDX1_RVT U122 ( .A(n82), .B(pixel_b[3]), .CI(n81), .CO(n32), .S(
        intadd_9_B_1_) );
  HADDX1_RVT U123 ( .A0(pixel_r[4]), .B0(n83), .SO(intadd_9_A_2_) );
endmodule


module crop_core ( x, y, in_width, in_height, crop_enable, x_start, y_start, 
        crop_width, crop_height, in_roi, u, v, roi_width, roi_height );
  input [10:0] x;
  input [10:0] y;
  input [10:0] in_width;
  input [10:0] in_height;
  input [10:0] x_start;
  input [10:0] y_start;
  input [10:0] crop_width;
  input [10:0] crop_height;
  output [10:0] u;
  output [10:0] v;
  output [10:0] roi_width;
  output [10:0] roi_height;
  input crop_enable;
  output in_roi;
  wire   intadd_12_A_8_, intadd_12_A_7_, intadd_12_A_6_, intadd_12_A_5_,
         intadd_12_A_4_, intadd_12_A_3_, intadd_12_A_2_, intadd_12_A_1_,
         intadd_12_A_0_, intadd_12_B_0_, intadd_12_SUM_8_, intadd_12_SUM_7_,
         intadd_12_SUM_6_, intadd_12_SUM_5_, intadd_12_SUM_4_,
         intadd_12_SUM_3_, intadd_12_SUM_2_, intadd_12_SUM_1_,
         intadd_12_SUM_0_, intadd_12_n9, intadd_12_n8, intadd_12_n7,
         intadd_12_n6, intadd_12_n5, intadd_12_n4, intadd_12_n3, intadd_12_n2,
         intadd_12_n1, intadd_13_A_8_, intadd_13_A_7_, intadd_13_A_6_,
         intadd_13_A_5_, intadd_13_A_4_, intadd_13_A_3_, intadd_13_A_2_,
         intadd_13_A_1_, intadd_13_A_0_, intadd_13_B_0_, intadd_13_SUM_8_,
         intadd_13_SUM_7_, intadd_13_SUM_6_, intadd_13_SUM_5_,
         intadd_13_SUM_4_, intadd_13_SUM_3_, intadd_13_SUM_2_,
         intadd_13_SUM_1_, intadd_13_SUM_0_, intadd_13_n9, intadd_13_n8,
         intadd_13_n7, intadd_13_n6, intadd_13_n5, intadd_13_n4, intadd_13_n3,
         intadd_13_n2, intadd_13_n1, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10,
         n11, n12, n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, n24,
         n25, n26, n27, n28, n29, n30, n31, n32, n33, n34, n35, n36, n37, n38,
         n39, n40, n41, n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52,
         n53, n54, n55, n56, n57, n58, n59, n60, n61, n62, n63, n64, n65, n66,
         n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80,
         n81, n82, n83, n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94,
         n95, n96, n97, n98, n99, n100, n101, n102, n103, n104, n105, n106,
         n107, n108, n109, n110, n111, n112, n113, n114, n115, n116, n117,
         n118, n119, n120, n121, n122, n123, n124, n125, n126, n127, n128,
         n129, n130, n131, n132, n133, n134, n135, n136, n137, n138, n139,
         n140, n141, n142, n143, n144, n145, n146, n147, n148, n149, n150,
         n151, n152, n153, n154;

  FADDX1_RVT intadd_12_U10 ( .A(intadd_12_B_0_), .B(intadd_12_A_0_), .CI(
        roi_width[1]), .CO(intadd_12_n9), .S(intadd_12_SUM_0_) );
  FADDX1_RVT intadd_12_U9 ( .A(roi_width[2]), .B(intadd_12_A_1_), .CI(
        intadd_12_n9), .CO(intadd_12_n8), .S(intadd_12_SUM_1_) );
  FADDX1_RVT intadd_12_U8 ( .A(roi_width[3]), .B(intadd_12_A_2_), .CI(
        intadd_12_n8), .CO(intadd_12_n7), .S(intadd_12_SUM_2_) );
  FADDX1_RVT intadd_12_U7 ( .A(roi_width[4]), .B(intadd_12_A_3_), .CI(
        intadd_12_n7), .CO(intadd_12_n6), .S(intadd_12_SUM_3_) );
  FADDX1_RVT intadd_12_U6 ( .A(roi_width[5]), .B(intadd_12_A_4_), .CI(
        intadd_12_n6), .CO(intadd_12_n5), .S(intadd_12_SUM_4_) );
  FADDX1_RVT intadd_12_U5 ( .A(roi_width[6]), .B(intadd_12_A_5_), .CI(
        intadd_12_n5), .CO(intadd_12_n4), .S(intadd_12_SUM_5_) );
  FADDX1_RVT intadd_12_U4 ( .A(roi_width[7]), .B(intadd_12_A_6_), .CI(
        intadd_12_n4), .CO(intadd_12_n3), .S(intadd_12_SUM_6_) );
  FADDX1_RVT intadd_12_U3 ( .A(roi_width[8]), .B(intadd_12_A_7_), .CI(
        intadd_12_n3), .CO(intadd_12_n2), .S(intadd_12_SUM_7_) );
  FADDX1_RVT intadd_12_U2 ( .A(roi_width[9]), .B(intadd_12_A_8_), .CI(
        intadd_12_n2), .CO(intadd_12_n1), .S(intadd_12_SUM_8_) );
  FADDX1_RVT intadd_13_U10 ( .A(intadd_13_B_0_), .B(intadd_13_A_0_), .CI(
        roi_height[1]), .CO(intadd_13_n9), .S(intadd_13_SUM_0_) );
  FADDX1_RVT intadd_13_U9 ( .A(roi_height[2]), .B(intadd_13_A_1_), .CI(
        intadd_13_n9), .CO(intadd_13_n8), .S(intadd_13_SUM_1_) );
  FADDX1_RVT intadd_13_U8 ( .A(roi_height[3]), .B(intadd_13_A_2_), .CI(
        intadd_13_n8), .CO(intadd_13_n7), .S(intadd_13_SUM_2_) );
  FADDX1_RVT intadd_13_U7 ( .A(roi_height[4]), .B(intadd_13_A_3_), .CI(
        intadd_13_n7), .CO(intadd_13_n6), .S(intadd_13_SUM_3_) );
  FADDX1_RVT intadd_13_U6 ( .A(roi_height[5]), .B(intadd_13_A_4_), .CI(
        intadd_13_n6), .CO(intadd_13_n5), .S(intadd_13_SUM_4_) );
  FADDX1_RVT intadd_13_U5 ( .A(roi_height[6]), .B(intadd_13_A_5_), .CI(
        intadd_13_n5), .CO(intadd_13_n4), .S(intadd_13_SUM_5_) );
  FADDX1_RVT intadd_13_U4 ( .A(roi_height[7]), .B(intadd_13_A_6_), .CI(
        intadd_13_n4), .CO(intadd_13_n3), .S(intadd_13_SUM_6_) );
  FADDX1_RVT intadd_13_U3 ( .A(roi_height[8]), .B(intadd_13_A_7_), .CI(
        intadd_13_n3), .CO(intadd_13_n2), .S(intadd_13_SUM_7_) );
  FADDX1_RVT intadd_13_U2 ( .A(roi_height[9]), .B(intadd_13_A_8_), .CI(
        intadd_13_n2), .CO(intadd_13_n1), .S(intadd_13_SUM_8_) );
  INVX2_RVT U2 ( .A(n109), .Y(in_roi) );
  INVX0_RVT U3 ( .A(crop_enable), .Y(n50) );
  NBUFFX2_RVT U4 ( .A(n50), .Y(n48) );
  INVX0_RVT U5 ( .A(n48), .Y(n47) );
  NAND2X0_RVT U6 ( .A1(n47), .A2(x_start[3]), .Y(n111) );
  INVX0_RVT U7 ( .A(n111), .Y(intadd_12_A_2_) );
  INVX0_RVT U8 ( .A(n48), .Y(n51) );
  AND2X1_RVT U9 ( .A1(n51), .A2(x_start[1]), .Y(intadd_12_A_0_) );
  AND2X1_RVT U10 ( .A1(n51), .A2(x_start[2]), .Y(intadd_12_A_1_) );
  NAND2X0_RVT U11 ( .A1(n47), .A2(x_start[4]), .Y(n117) );
  INVX0_RVT U12 ( .A(n117), .Y(intadd_12_A_3_) );
  NAND2X0_RVT U13 ( .A1(n47), .A2(x_start[5]), .Y(n123) );
  INVX0_RVT U14 ( .A(n123), .Y(intadd_12_A_4_) );
  NAND2X0_RVT U15 ( .A1(n47), .A2(x_start[6]), .Y(n129) );
  INVX0_RVT U16 ( .A(n129), .Y(intadd_12_A_5_) );
  NAND2X0_RVT U17 ( .A1(n47), .A2(x_start[7]), .Y(n135) );
  INVX0_RVT U18 ( .A(n135), .Y(intadd_12_A_6_) );
  INVX0_RVT U19 ( .A(n50), .Y(n2) );
  NAND2X0_RVT U20 ( .A1(n2), .A2(x_start[8]), .Y(n141) );
  INVX0_RVT U21 ( .A(n141), .Y(intadd_12_A_7_) );
  NAND2X0_RVT U22 ( .A1(n47), .A2(y_start[3]), .Y(n59) );
  INVX0_RVT U23 ( .A(n59), .Y(intadd_13_A_2_) );
  AND2X1_RVT U24 ( .A1(n51), .A2(y_start[1]), .Y(intadd_13_A_0_) );
  AND2X1_RVT U25 ( .A1(n51), .A2(y_start[2]), .Y(intadd_13_A_1_) );
  NAND2X0_RVT U26 ( .A1(n47), .A2(y_start[4]), .Y(n65) );
  INVX0_RVT U27 ( .A(n65), .Y(intadd_13_A_3_) );
  NAND2X0_RVT U28 ( .A1(n47), .A2(y_start[5]), .Y(n71) );
  INVX0_RVT U29 ( .A(n71), .Y(intadd_13_A_4_) );
  NAND2X0_RVT U30 ( .A1(n2), .A2(y_start[6]), .Y(n77) );
  INVX0_RVT U31 ( .A(n77), .Y(intadd_13_A_5_) );
  NAND2X0_RVT U32 ( .A1(n2), .A2(y_start[7]), .Y(n83) );
  INVX0_RVT U33 ( .A(n83), .Y(intadd_13_A_6_) );
  NAND2X0_RVT U34 ( .A1(n2), .A2(y_start[8]), .Y(n89) );
  INVX0_RVT U35 ( .A(n89), .Y(intadd_13_A_7_) );
  INVX0_RVT U36 ( .A(n48), .Y(n49) );
  AO22X1_RVT U37 ( .A1(n49), .A2(crop_height[10]), .A3(n48), .A4(in_height[10]), .Y(roi_height[10]) );
  AO22X1_RVT U38 ( .A1(n51), .A2(crop_height[0]), .A3(n50), .A4(in_height[0]), 
        .Y(roi_height[0]) );
  AO22X1_RVT U39 ( .A1(n49), .A2(crop_width[10]), .A3(n48), .A4(in_width[10]), 
        .Y(roi_width[10]) );
  AO22X1_RVT U40 ( .A1(n49), .A2(crop_width[0]), .A3(n50), .A4(in_width[0]), 
        .Y(roi_width[0]) );
  NAND2X0_RVT U41 ( .A1(n47), .A2(y_start[10]), .Y(n3) );
  INVX0_RVT U42 ( .A(x[3]), .Y(n112) );
  INVX0_RVT U43 ( .A(x[2]), .Y(n108) );
  INVX0_RVT U44 ( .A(x[1]), .Y(n105) );
  NAND2X0_RVT U45 ( .A1(n47), .A2(x_start[0]), .Y(n103) );
  INVX0_RVT U46 ( .A(n103), .Y(n22) );
  INVX0_RVT U47 ( .A(x[0]), .Y(n21) );
  AND2X1_RVT U48 ( .A1(n22), .A2(n21), .Y(n104) );
  OA222X1_RVT U49 ( .A1(n112), .A2(intadd_12_A_2_), .A3(n112), .A4(n116), .A5(
        intadd_12_A_2_), .A6(n116), .Y(n120) );
  INVX0_RVT U50 ( .A(x[4]), .Y(n118) );
  OA222X1_RVT U51 ( .A1(n120), .A2(n118), .A3(n120), .A4(intadd_12_A_3_), .A5(
        n118), .A6(intadd_12_A_3_), .Y(n126) );
  INVX0_RVT U52 ( .A(x[5]), .Y(n124) );
  OA222X1_RVT U53 ( .A1(n126), .A2(n124), .A3(n126), .A4(intadd_12_A_4_), .A5(
        n124), .A6(intadd_12_A_4_), .Y(n132) );
  INVX0_RVT U54 ( .A(x[6]), .Y(n130) );
  OA222X1_RVT U55 ( .A1(n132), .A2(n130), .A3(n132), .A4(intadd_12_A_5_), .A5(
        n130), .A6(intadd_12_A_5_), .Y(n138) );
  INVX0_RVT U56 ( .A(x[7]), .Y(n136) );
  OA222X1_RVT U57 ( .A1(n138), .A2(n136), .A3(n138), .A4(intadd_12_A_6_), .A5(
        n136), .A6(intadd_12_A_6_), .Y(n144) );
  INVX0_RVT U58 ( .A(x[8]), .Y(n142) );
  OA222X1_RVT U59 ( .A1(n144), .A2(n142), .A3(n144), .A4(intadd_12_A_7_), .A5(
        n142), .A6(intadd_12_A_7_), .Y(n150) );
  INVX0_RVT U60 ( .A(n150), .Y(n152) );
  NAND2X0_RVT U61 ( .A1(n47), .A2(x_start[9]), .Y(n147) );
  AO222X1_RVT U62 ( .A1(n152), .A2(x[9]), .A3(n152), .A4(n147), .A5(x[9]), 
        .A6(n147), .Y(n1) );
  OA22X1_RVT U63 ( .A1(y[10]), .A2(n3), .A3(x[10]), .A4(n1), .Y(n44) );
  AND2X1_RVT U64 ( .A1(x[10]), .A2(n1), .Y(n154) );
  NAND2X0_RVT U65 ( .A1(n47), .A2(x_start[10]), .Y(n153) );
  AND2X1_RVT U66 ( .A1(y[10]), .A2(n3), .Y(n102) );
  INVX0_RVT U67 ( .A(y[3]), .Y(n60) );
  INVX0_RVT U68 ( .A(y[2]), .Y(n57) );
  INVX0_RVT U69 ( .A(y[1]), .Y(n54) );
  NAND2X0_RVT U70 ( .A1(n47), .A2(y_start[0]), .Y(n52) );
  INVX0_RVT U71 ( .A(n52), .Y(n5) );
  INVX0_RVT U72 ( .A(y[0]), .Y(n4) );
  AND2X1_RVT U73 ( .A1(n5), .A2(n4), .Y(n53) );
  OA222X1_RVT U74 ( .A1(n60), .A2(intadd_13_A_2_), .A3(n60), .A4(n64), .A5(
        intadd_13_A_2_), .A6(n64), .Y(n68) );
  INVX0_RVT U75 ( .A(y[4]), .Y(n66) );
  OA222X1_RVT U76 ( .A1(n68), .A2(n66), .A3(n68), .A4(intadd_13_A_3_), .A5(n66), .A6(intadd_13_A_3_), .Y(n74) );
  INVX0_RVT U77 ( .A(y[5]), .Y(n72) );
  OA222X1_RVT U78 ( .A1(n74), .A2(n72), .A3(n74), .A4(intadd_13_A_4_), .A5(n72), .A6(intadd_13_A_4_), .Y(n80) );
  INVX0_RVT U79 ( .A(y[6]), .Y(n78) );
  OA222X1_RVT U80 ( .A1(n80), .A2(n78), .A3(n80), .A4(intadd_13_A_5_), .A5(n78), .A6(intadd_13_A_5_), .Y(n86) );
  INVX0_RVT U81 ( .A(y[7]), .Y(n84) );
  OA222X1_RVT U82 ( .A1(n86), .A2(n84), .A3(n86), .A4(intadd_13_A_6_), .A5(n84), .A6(intadd_13_A_6_), .Y(n92) );
  INVX0_RVT U83 ( .A(y[8]), .Y(n90) );
  OA222X1_RVT U84 ( .A1(n92), .A2(n90), .A3(n92), .A4(intadd_13_A_7_), .A5(n90), .A6(intadd_13_A_7_), .Y(n98) );
  INVX0_RVT U85 ( .A(n98), .Y(n100) );
  NAND2X0_RVT U86 ( .A1(n2), .A2(y_start[9]), .Y(n95) );
  AO222X1_RVT U87 ( .A1(n100), .A2(y[9]), .A3(n100), .A4(n95), .A5(y[9]), .A6(
        n95), .Y(n101) );
  OA22X1_RVT U88 ( .A1(n154), .A2(n153), .A3(n102), .A4(n101), .Y(n43) );
  INVX0_RVT U89 ( .A(y[10]), .Y(n19) );
  INVX0_RVT U90 ( .A(n3), .Y(n20) );
  OR3X1_RVT U91 ( .A1(intadd_13_n1), .A2(n20), .A3(roi_height[10]), .Y(n18) );
  NAND3X0_RVT U92 ( .A1(n51), .A2(y_start[0]), .A3(crop_height[0]), .Y(n46) );
  AND2X1_RVT U93 ( .A1(n46), .A2(n4), .Y(n7) );
  OR2X1_RVT U94 ( .A1(roi_height[0]), .A2(n5), .Y(n6) );
  AND2X1_RVT U95 ( .A1(n7), .A2(n6), .Y(n8) );
  AO222X1_RVT U96 ( .A1(intadd_13_SUM_0_), .A2(n8), .A3(intadd_13_SUM_0_), 
        .A4(n54), .A5(n8), .A6(n54), .Y(n9) );
  AO222X1_RVT U97 ( .A1(intadd_13_SUM_1_), .A2(n57), .A3(intadd_13_SUM_1_), 
        .A4(n9), .A5(n57), .A6(n9), .Y(n10) );
  AO222X1_RVT U98 ( .A1(intadd_13_SUM_2_), .A2(n60), .A3(intadd_13_SUM_2_), 
        .A4(n10), .A5(n60), .A6(n10), .Y(n11) );
  AO222X1_RVT U99 ( .A1(intadd_13_SUM_3_), .A2(n66), .A3(intadd_13_SUM_3_), 
        .A4(n11), .A5(n66), .A6(n11), .Y(n12) );
  AO222X1_RVT U100 ( .A1(intadd_13_SUM_4_), .A2(n72), .A3(intadd_13_SUM_4_), 
        .A4(n12), .A5(n72), .A6(n12), .Y(n13) );
  AO222X1_RVT U101 ( .A1(intadd_13_SUM_5_), .A2(n78), .A3(intadd_13_SUM_5_), 
        .A4(n13), .A5(n78), .A6(n13), .Y(n14) );
  AO222X1_RVT U102 ( .A1(intadd_13_SUM_6_), .A2(n84), .A3(intadd_13_SUM_6_), 
        .A4(n14), .A5(n84), .A6(n14), .Y(n15) );
  AO222X1_RVT U103 ( .A1(intadd_13_SUM_7_), .A2(n90), .A3(intadd_13_SUM_7_), 
        .A4(n15), .A5(n90), .A6(n15), .Y(n16) );
  INVX0_RVT U104 ( .A(y[9]), .Y(n96) );
  AO222X1_RVT U105 ( .A1(intadd_13_SUM_8_), .A2(n16), .A3(intadd_13_SUM_8_), 
        .A4(n96), .A5(n16), .A6(n96), .Y(n17) );
  AO222X1_RVT U106 ( .A1(n19), .A2(n18), .A3(n19), .A4(n17), .A5(n18), .A6(n17), .Y(n41) );
  AO222X1_RVT U107 ( .A1(intadd_13_n1), .A2(n20), .A3(intadd_13_n1), .A4(
        roi_height[10]), .A5(n20), .A6(roi_height[10]), .Y(n40) );
  INVX0_RVT U108 ( .A(n153), .Y(n34) );
  AO222X1_RVT U109 ( .A1(n34), .A2(intadd_12_n1), .A3(n34), .A4(roi_width[10]), 
        .A5(intadd_12_n1), .A6(roi_width[10]), .Y(n39) );
  NAND3X0_RVT U110 ( .A1(n51), .A2(x_start[0]), .A3(crop_width[0]), .Y(n45) );
  AND2X1_RVT U111 ( .A1(n45), .A2(n21), .Y(n24) );
  OR2X1_RVT U112 ( .A1(roi_width[0]), .A2(n22), .Y(n23) );
  AND2X1_RVT U113 ( .A1(n24), .A2(n23), .Y(n25) );
  AO222X1_RVT U114 ( .A1(intadd_12_SUM_0_), .A2(n25), .A3(intadd_12_SUM_0_), 
        .A4(n105), .A5(n25), .A6(n105), .Y(n26) );
  AO222X1_RVT U115 ( .A1(intadd_12_SUM_1_), .A2(n108), .A3(intadd_12_SUM_1_), 
        .A4(n26), .A5(n108), .A6(n26), .Y(n27) );
  AO222X1_RVT U116 ( .A1(intadd_12_SUM_2_), .A2(n112), .A3(intadd_12_SUM_2_), 
        .A4(n27), .A5(n112), .A6(n27), .Y(n28) );
  AO222X1_RVT U117 ( .A1(intadd_12_SUM_3_), .A2(n118), .A3(intadd_12_SUM_3_), 
        .A4(n28), .A5(n118), .A6(n28), .Y(n29) );
  AO222X1_RVT U118 ( .A1(intadd_12_SUM_4_), .A2(n124), .A3(intadd_12_SUM_4_), 
        .A4(n29), .A5(n124), .A6(n29), .Y(n30) );
  AO222X1_RVT U119 ( .A1(intadd_12_SUM_5_), .A2(n130), .A3(intadd_12_SUM_5_), 
        .A4(n30), .A5(n130), .A6(n30), .Y(n31) );
  AO222X1_RVT U120 ( .A1(intadd_12_SUM_6_), .A2(n136), .A3(intadd_12_SUM_6_), 
        .A4(n31), .A5(n136), .A6(n31), .Y(n32) );
  AO222X1_RVT U121 ( .A1(intadd_12_SUM_7_), .A2(n142), .A3(intadd_12_SUM_7_), 
        .A4(n32), .A5(n142), .A6(n32), .Y(n33) );
  INVX0_RVT U122 ( .A(x[9]), .Y(n148) );
  AO222X1_RVT U123 ( .A1(intadd_12_SUM_8_), .A2(n33), .A3(intadd_12_SUM_8_), 
        .A4(n148), .A5(n33), .A6(n148), .Y(n37) );
  OR3X1_RVT U124 ( .A1(n34), .A2(intadd_12_n1), .A3(roi_width[10]), .Y(n36) );
  INVX0_RVT U125 ( .A(x[10]), .Y(n35) );
  AO222X1_RVT U126 ( .A1(n37), .A2(n36), .A3(n37), .A4(n35), .A5(n36), .A6(n35), .Y(n38) );
  OA22X1_RVT U127 ( .A1(n41), .A2(n40), .A3(n39), .A4(n38), .Y(n42) );
  NAND3X0_RVT U128 ( .A1(n44), .A2(n43), .A3(n42), .Y(n109) );
  INVX0_RVT U129 ( .A(n45), .Y(intadd_12_B_0_) );
  INVX0_RVT U130 ( .A(n147), .Y(intadd_12_A_8_) );
  INVX0_RVT U131 ( .A(n46), .Y(intadd_13_B_0_) );
  INVX0_RVT U132 ( .A(n95), .Y(intadd_13_A_8_) );
  AO22X1_RVT U133 ( .A1(n51), .A2(crop_width[9]), .A3(n48), .A4(in_width[9]), 
        .Y(roi_width[9]) );
  AO22X1_RVT U134 ( .A1(n49), .A2(crop_width[8]), .A3(n48), .A4(in_width[8]), 
        .Y(roi_width[8]) );
  AO22X1_RVT U135 ( .A1(n47), .A2(crop_width[7]), .A3(n48), .A4(in_width[7]), 
        .Y(roi_width[7]) );
  AO22X1_RVT U136 ( .A1(n49), .A2(crop_width[6]), .A3(n48), .A4(in_width[6]), 
        .Y(roi_width[6]) );
  AO22X1_RVT U137 ( .A1(n49), .A2(crop_width[5]), .A3(n50), .A4(in_width[5]), 
        .Y(roi_width[5]) );
  AO22X1_RVT U138 ( .A1(n49), .A2(crop_width[4]), .A3(n50), .A4(in_width[4]), 
        .Y(roi_width[4]) );
  AO22X1_RVT U139 ( .A1(n49), .A2(crop_width[3]), .A3(n50), .A4(in_width[3]), 
        .Y(roi_width[3]) );
  AO22X1_RVT U140 ( .A1(n49), .A2(crop_width[2]), .A3(n50), .A4(in_width[2]), 
        .Y(roi_width[2]) );
  AO22X1_RVT U141 ( .A1(n49), .A2(crop_width[1]), .A3(n50), .A4(in_width[1]), 
        .Y(roi_width[1]) );
  AO22X1_RVT U142 ( .A1(n49), .A2(crop_height[9]), .A3(n48), .A4(in_height[9]), 
        .Y(roi_height[9]) );
  AO22X1_RVT U143 ( .A1(n49), .A2(crop_height[8]), .A3(n48), .A4(in_height[8]), 
        .Y(roi_height[8]) );
  AO22X1_RVT U144 ( .A1(n49), .A2(crop_height[7]), .A3(n50), .A4(in_height[7]), 
        .Y(roi_height[7]) );
  AO22X1_RVT U145 ( .A1(n49), .A2(crop_height[6]), .A3(n50), .A4(in_height[6]), 
        .Y(roi_height[6]) );
  AO22X1_RVT U146 ( .A1(n51), .A2(crop_height[5]), .A3(n50), .A4(in_height[5]), 
        .Y(roi_height[5]) );
  AO22X1_RVT U147 ( .A1(n51), .A2(crop_height[4]), .A3(n50), .A4(in_height[4]), 
        .Y(roi_height[4]) );
  AO22X1_RVT U148 ( .A1(n51), .A2(crop_height[3]), .A3(n50), .A4(in_height[3]), 
        .Y(roi_height[3]) );
  AO22X1_RVT U149 ( .A1(n51), .A2(crop_height[2]), .A3(n50), .A4(in_height[2]), 
        .Y(roi_height[2]) );
  AO22X1_RVT U150 ( .A1(n51), .A2(crop_height[1]), .A3(n50), .A4(in_height[1]), 
        .Y(roi_height[1]) );
  OA221X1_RVT U151 ( .A1(n53), .A2(y[0]), .A3(n53), .A4(n52), .A5(in_roi), .Y(
        v[0]) );
  FADDX1_RVT U152 ( .A(n54), .B(intadd_13_A_0_), .CI(n53), .CO(n56), .S(n55)
         );
  NOR2X0_RVT U153 ( .A1(n55), .A2(n109), .Y(v[1]) );
  FADDX1_RVT U154 ( .A(n57), .B(n56), .CI(intadd_13_A_1_), .CO(n64), .S(n58)
         );
  NOR2X0_RVT U155 ( .A1(n58), .A2(n109), .Y(v[2]) );
  OA22X1_RVT U156 ( .A1(n60), .A2(intadd_13_A_2_), .A3(y[3]), .A4(n59), .Y(n61) );
  INVX0_RVT U157 ( .A(n61), .Y(n63) );
  INVX0_RVT U158 ( .A(n64), .Y(n62) );
  OA221X1_RVT U159 ( .A1(n64), .A2(n63), .A3(n62), .A4(n61), .A5(in_roi), .Y(
        v[3]) );
  INVX0_RVT U160 ( .A(n68), .Y(n70) );
  OA22X1_RVT U161 ( .A1(n66), .A2(n65), .A3(y[4]), .A4(intadd_13_A_3_), .Y(n67) );
  INVX0_RVT U162 ( .A(n67), .Y(n69) );
  OA221X1_RVT U163 ( .A1(n70), .A2(n69), .A3(n68), .A4(n67), .A5(in_roi), .Y(
        v[4]) );
  INVX0_RVT U164 ( .A(n74), .Y(n76) );
  OA22X1_RVT U165 ( .A1(n72), .A2(n71), .A3(y[5]), .A4(intadd_13_A_4_), .Y(n73) );
  INVX0_RVT U166 ( .A(n73), .Y(n75) );
  OA221X1_RVT U167 ( .A1(n76), .A2(n75), .A3(n74), .A4(n73), .A5(in_roi), .Y(
        v[5]) );
  INVX0_RVT U168 ( .A(n80), .Y(n82) );
  OA22X1_RVT U169 ( .A1(n78), .A2(n77), .A3(y[6]), .A4(intadd_13_A_5_), .Y(n79) );
  INVX0_RVT U170 ( .A(n79), .Y(n81) );
  OA221X1_RVT U171 ( .A1(n82), .A2(n81), .A3(n80), .A4(n79), .A5(in_roi), .Y(
        v[6]) );
  INVX0_RVT U172 ( .A(n86), .Y(n88) );
  OA22X1_RVT U173 ( .A1(n84), .A2(n83), .A3(y[7]), .A4(intadd_13_A_6_), .Y(n85) );
  INVX0_RVT U174 ( .A(n85), .Y(n87) );
  OA221X1_RVT U175 ( .A1(n88), .A2(n87), .A3(n86), .A4(n85), .A5(in_roi), .Y(
        v[7]) );
  INVX0_RVT U176 ( .A(n92), .Y(n94) );
  OA22X1_RVT U177 ( .A1(n90), .A2(n89), .A3(y[8]), .A4(intadd_13_A_7_), .Y(n91) );
  INVX0_RVT U178 ( .A(n91), .Y(n93) );
  OA221X1_RVT U179 ( .A1(n94), .A2(n93), .A3(n92), .A4(n91), .A5(in_roi), .Y(
        v[8]) );
  OA22X1_RVT U180 ( .A1(n96), .A2(n95), .A3(y[9]), .A4(intadd_13_A_8_), .Y(n97) );
  INVX0_RVT U181 ( .A(n97), .Y(n99) );
  OA221X1_RVT U182 ( .A1(n100), .A2(n99), .A3(n98), .A4(n97), .A5(in_roi), .Y(
        v[9]) );
  AND3X1_RVT U183 ( .A1(n102), .A2(n101), .A3(in_roi), .Y(v[10]) );
  OA221X1_RVT U184 ( .A1(n104), .A2(x[0]), .A3(n104), .A4(n103), .A5(in_roi), 
        .Y(u[0]) );
  FADDX1_RVT U185 ( .A(n105), .B(intadd_12_A_0_), .CI(n104), .CO(n107), .S(
        n106) );
  NOR2X0_RVT U186 ( .A1(n106), .A2(n109), .Y(u[1]) );
  FADDX1_RVT U187 ( .A(n108), .B(n107), .CI(intadd_12_A_1_), .CO(n116), .S(
        n110) );
  NOR2X0_RVT U188 ( .A1(n110), .A2(n109), .Y(u[2]) );
  OA22X1_RVT U189 ( .A1(n112), .A2(intadd_12_A_2_), .A3(x[3]), .A4(n111), .Y(
        n113) );
  INVX0_RVT U190 ( .A(n113), .Y(n115) );
  INVX0_RVT U191 ( .A(n116), .Y(n114) );
  OA221X1_RVT U192 ( .A1(n116), .A2(n115), .A3(n114), .A4(n113), .A5(in_roi), 
        .Y(u[3]) );
  INVX0_RVT U193 ( .A(n120), .Y(n122) );
  OA22X1_RVT U194 ( .A1(n118), .A2(n117), .A3(x[4]), .A4(intadd_12_A_3_), .Y(
        n119) );
  INVX0_RVT U195 ( .A(n119), .Y(n121) );
  OA221X1_RVT U196 ( .A1(n122), .A2(n121), .A3(n120), .A4(n119), .A5(in_roi), 
        .Y(u[4]) );
  INVX0_RVT U197 ( .A(n126), .Y(n128) );
  OA22X1_RVT U198 ( .A1(n124), .A2(n123), .A3(x[5]), .A4(intadd_12_A_4_), .Y(
        n125) );
  INVX0_RVT U199 ( .A(n125), .Y(n127) );
  OA221X1_RVT U200 ( .A1(n128), .A2(n127), .A3(n126), .A4(n125), .A5(in_roi), 
        .Y(u[5]) );
  INVX0_RVT U201 ( .A(n132), .Y(n134) );
  OA22X1_RVT U202 ( .A1(n130), .A2(n129), .A3(x[6]), .A4(intadd_12_A_5_), .Y(
        n131) );
  INVX0_RVT U203 ( .A(n131), .Y(n133) );
  OA221X1_RVT U204 ( .A1(n134), .A2(n133), .A3(n132), .A4(n131), .A5(in_roi), 
        .Y(u[6]) );
  INVX0_RVT U205 ( .A(n138), .Y(n140) );
  OA22X1_RVT U206 ( .A1(n136), .A2(n135), .A3(x[7]), .A4(intadd_12_A_6_), .Y(
        n137) );
  INVX0_RVT U207 ( .A(n137), .Y(n139) );
  OA221X1_RVT U208 ( .A1(n140), .A2(n139), .A3(n138), .A4(n137), .A5(in_roi), 
        .Y(u[7]) );
  INVX0_RVT U209 ( .A(n144), .Y(n146) );
  OA22X1_RVT U210 ( .A1(n142), .A2(n141), .A3(x[8]), .A4(intadd_12_A_7_), .Y(
        n143) );
  INVX0_RVT U211 ( .A(n143), .Y(n145) );
  OA221X1_RVT U212 ( .A1(n146), .A2(n145), .A3(n144), .A4(n143), .A5(in_roi), 
        .Y(u[8]) );
  OA22X1_RVT U213 ( .A1(n148), .A2(n147), .A3(x[9]), .A4(intadd_12_A_8_), .Y(
        n149) );
  INVX0_RVT U214 ( .A(n149), .Y(n151) );
  OA221X1_RVT U215 ( .A1(n152), .A2(n151), .A3(n150), .A4(n149), .A5(in_roi), 
        .Y(u[9]) );
  AND3X1_RVT U216 ( .A1(n154), .A2(in_roi), .A3(n153), .Y(u[10]) );
endmodule


module resize_nn_core ( in_roi, u, v, roi_width, roi_height, resize_x2, 
        resize_y2, out_width, out_height, sel_pixel, x_out, y_out, out_sof, 
        out_sol, out_eol, out_eof );
  input [10:0] u;
  input [10:0] v;
  input [10:0] roi_width;
  input [10:0] roi_height;
  output [10:0] out_width;
  output [10:0] out_height;
  output [10:0] x_out;
  output [10:0] y_out;
  input in_roi, resize_x2, resize_y2;
  output sel_pixel, out_sof, out_sol, out_eol, out_eof;
  wire   n45, n46, n47, n48, n49, n50, n51, n52, n53, n54, n55, n56, n57, n58,
         n59, n60, n61, n62, n63, n64, n65, n66, n67, n68, n69, n70, n71, n72,
         n73, n74, n75, n76, n77, n78, n79, n80, n81, n82, n83, n84, n85, n86,
         n87, n88, n89, n90, n91, n92, n93, n94, n95, n96, n97, n98, n99, n100,
         n101, n102, n103, n104, n105, n106, n107, n108, n109, n110, n111,
         n112, n113, n114, n115, n116, n117, n118, n119, n120, n121, n122,
         n123, n124, n125, n126, n127, n128, n129, n130, n131, n132, n133,
         n134, n135, n136, n137, n138, n139, n140, n141, n142, n143, n144,
         n145, n146, n147, n148, n149, n150, n151, n152, n153, n154, n155,
         n156, n157, n158, n159, n160, n161, n162, n163, n164, n165, n166,
         n167, n168, n169, n170, n171, n172, n173, n174, n175, n176, n177,
         n178, n179, n180, n181, n182, n183, n184, n185, n186, n187, n188,
         n189, n190, n191, n192, n193, n194, n195, n196, n197, n198, n199,
         n200, n201, n202, n203, n204, n205, n206, n207, n208, n209, n210,
         n211, n212, n213, n214, n215, n216, n217, n218, n219, n220, n221,
         n222, n223, n224, n225, n226, n227, n228, n229, n230, n231, n232,
         n233, n234, n235, n236, n237, n238, n239, n240, n241, n242, n243;

  INVX2_RVT U3 ( .A(resize_y2), .Y(n219) );
  INVX2_RVT U4 ( .A(resize_x2), .Y(n142) );
  INVX0_RVT U5 ( .A(n178), .Y(n46) );
  INVX0_RVT U6 ( .A(n101), .Y(n49) );
  NAND2X0_RVT U7 ( .A1(n179), .A2(n45), .Y(n181) );
  INVX0_RVT U8 ( .A(n200), .Y(n47) );
  NAND2X0_RVT U9 ( .A1(n47), .A2(n46), .Y(n45) );
  NAND2X0_RVT U10 ( .A1(n102), .A2(n48), .Y(n104) );
  INVX0_RVT U11 ( .A(n123), .Y(n50) );
  NAND2X0_RVT U12 ( .A1(n50), .A2(n49), .Y(n48) );
  INVX0_RVT U13 ( .A(v[10]), .Y(n224) );
  OA22X1_RVT U14 ( .A1(n219), .A2(roi_height[10]), .A3(resize_y2), .A4(
        roi_height[9]), .Y(n220) );
  NAND2X0_RVT U15 ( .A1(n224), .A2(n220), .Y(n61) );
  OAI22X1_RVT U16 ( .A1(n219), .A2(roi_height[2]), .A3(resize_y2), .A4(
        roi_height[1]), .Y(n184) );
  AOI22X1_RVT U17 ( .A1(resize_y2), .A2(roi_height[1]), .A3(n219), .A4(
        roi_height[0]), .Y(n183) );
  OR2X1_RVT U18 ( .A1(v[1]), .A2(n183), .Y(n51) );
  AO222X1_RVT U19 ( .A1(v[2]), .A2(n184), .A3(v[2]), .A4(n51), .A5(n184), .A6(
        n51), .Y(n52) );
  OAI22X1_RVT U20 ( .A1(n219), .A2(roi_height[3]), .A3(resize_y2), .A4(
        roi_height[2]), .Y(n187) );
  AO222X1_RVT U21 ( .A1(v[3]), .A2(n52), .A3(v[3]), .A4(n187), .A5(n52), .A6(
        n187), .Y(n53) );
  OA22X1_RVT U22 ( .A1(n219), .A2(roi_height[4]), .A3(resize_y2), .A4(
        roi_height[3]), .Y(n169) );
  INVX0_RVT U23 ( .A(n169), .Y(n198) );
  AO222X1_RVT U24 ( .A1(v[4]), .A2(n53), .A3(v[4]), .A4(n198), .A5(n53), .A6(
        n198), .Y(n55) );
  OA22X1_RVT U25 ( .A1(n219), .A2(roi_height[5]), .A3(resize_y2), .A4(
        roi_height[4]), .Y(n176) );
  INVX0_RVT U26 ( .A(n176), .Y(n54) );
  AO222X1_RVT U27 ( .A1(v[5]), .A2(n55), .A3(v[5]), .A4(n54), .A5(n55), .A6(
        n54), .Y(n56) );
  OA22X1_RVT U28 ( .A1(n219), .A2(roi_height[6]), .A3(resize_y2), .A4(
        roi_height[5]), .Y(n178) );
  AO222X1_RVT U29 ( .A1(v[6]), .A2(n56), .A3(v[6]), .A4(n46), .A5(n56), .A6(
        n46), .Y(n57) );
  OA22X1_RVT U30 ( .A1(n219), .A2(roi_height[7]), .A3(resize_y2), .A4(
        roi_height[6]), .Y(n216) );
  INVX0_RVT U31 ( .A(n216), .Y(n202) );
  AO222X1_RVT U32 ( .A1(v[7]), .A2(n57), .A3(v[7]), .A4(n202), .A5(n57), .A6(
        n202), .Y(n58) );
  OAI22X1_RVT U33 ( .A1(n219), .A2(roi_height[8]), .A3(resize_y2), .A4(
        roi_height[7]), .Y(n204) );
  AO222X1_RVT U34 ( .A1(v[8]), .A2(n58), .A3(v[8]), .A4(n204), .A5(n58), .A6(
        n204), .Y(n59) );
  OA22X1_RVT U35 ( .A1(n219), .A2(roi_height[9]), .A3(resize_y2), .A4(
        roi_height[8]), .Y(n211) );
  INVX0_RVT U36 ( .A(n211), .Y(n229) );
  AO222X1_RVT U37 ( .A1(v[9]), .A2(n59), .A3(v[9]), .A4(n229), .A5(n59), .A6(
        n229), .Y(n60) );
  INVX0_RVT U38 ( .A(n220), .Y(n232) );
  AO221X1_RVT U39 ( .A1(n61), .A2(n60), .A3(n232), .A4(v[10]), .A5(v[0]), .Y(
        n74) );
  INVX0_RVT U40 ( .A(u[10]), .Y(n147) );
  OA22X1_RVT U41 ( .A1(n142), .A2(roi_width[10]), .A3(resize_x2), .A4(
        roi_width[9]), .Y(n143) );
  NAND2X0_RVT U42 ( .A1(n147), .A2(n143), .Y(n72) );
  OAI22X1_RVT U43 ( .A1(n142), .A2(roi_width[2]), .A3(resize_x2), .A4(
        roi_width[1]), .Y(n107) );
  AOI22X1_RVT U44 ( .A1(resize_x2), .A2(roi_width[1]), .A3(n142), .A4(
        roi_width[0]), .Y(n106) );
  OR2X1_RVT U45 ( .A1(u[1]), .A2(n106), .Y(n62) );
  AO222X1_RVT U46 ( .A1(u[2]), .A2(n107), .A3(u[2]), .A4(n62), .A5(n107), .A6(
        n62), .Y(n63) );
  OAI22X1_RVT U47 ( .A1(n142), .A2(roi_width[3]), .A3(resize_x2), .A4(
        roi_width[2]), .Y(n110) );
  AO222X1_RVT U48 ( .A1(u[3]), .A2(n63), .A3(u[3]), .A4(n110), .A5(n63), .A6(
        n110), .Y(n64) );
  OA22X1_RVT U49 ( .A1(n142), .A2(roi_width[4]), .A3(resize_x2), .A4(
        roi_width[3]), .Y(n92) );
  INVX0_RVT U50 ( .A(n92), .Y(n121) );
  AO222X1_RVT U51 ( .A1(u[4]), .A2(n64), .A3(u[4]), .A4(n121), .A5(n64), .A6(
        n121), .Y(n66) );
  OA22X1_RVT U52 ( .A1(n142), .A2(roi_width[5]), .A3(resize_x2), .A4(
        roi_width[4]), .Y(n99) );
  INVX0_RVT U53 ( .A(n99), .Y(n65) );
  AO222X1_RVT U54 ( .A1(u[5]), .A2(n66), .A3(u[5]), .A4(n65), .A5(n66), .A6(
        n65), .Y(n67) );
  OA22X1_RVT U55 ( .A1(n142), .A2(roi_width[6]), .A3(resize_x2), .A4(
        roi_width[5]), .Y(n101) );
  AO222X1_RVT U56 ( .A1(u[6]), .A2(n67), .A3(u[6]), .A4(n49), .A5(n67), .A6(
        n49), .Y(n68) );
  OA22X1_RVT U57 ( .A1(n142), .A2(roi_width[7]), .A3(resize_x2), .A4(
        roi_width[6]), .Y(n139) );
  INVX0_RVT U58 ( .A(n139), .Y(n125) );
  AO222X1_RVT U59 ( .A1(u[7]), .A2(n68), .A3(u[7]), .A4(n125), .A5(n68), .A6(
        n125), .Y(n69) );
  OAI22X1_RVT U60 ( .A1(n142), .A2(roi_width[8]), .A3(resize_x2), .A4(
        roi_width[7]), .Y(n127) );
  AO222X1_RVT U61 ( .A1(u[8]), .A2(n69), .A3(u[8]), .A4(n127), .A5(n69), .A6(
        n127), .Y(n70) );
  OA22X1_RVT U62 ( .A1(n142), .A2(roi_width[9]), .A3(resize_x2), .A4(
        roi_width[8]), .Y(n134) );
  INVX0_RVT U63 ( .A(n134), .Y(n152) );
  AO222X1_RVT U64 ( .A1(u[9]), .A2(n70), .A3(u[9]), .A4(n152), .A5(n70), .A6(
        n152), .Y(n71) );
  INVX0_RVT U65 ( .A(n143), .Y(n155) );
  AO221X1_RVT U66 ( .A1(n72), .A2(n71), .A3(n155), .A4(u[10]), .A5(u[0]), .Y(
        n73) );
  AOI22X1_RVT U67 ( .A1(resize_y2), .A2(n74), .A3(resize_x2), .A4(n73), .Y(n83) );
  NOR3X0_RVT U68 ( .A1(roi_height[2]), .A2(roi_height[1]), .A3(roi_height[10]), 
        .Y(n77) );
  NOR4X1_RVT U69 ( .A1(roi_height[0]), .A2(roi_height[3]), .A3(roi_height[4]), 
        .A4(roi_height[5]), .Y(n76) );
  NOR4X1_RVT U70 ( .A1(roi_height[6]), .A2(roi_height[7]), .A3(roi_height[8]), 
        .A4(roi_height[9]), .Y(n75) );
  NAND3X0_RVT U71 ( .A1(n77), .A2(n76), .A3(n75), .Y(n82) );
  NOR3X0_RVT U72 ( .A1(roi_width[0]), .A2(roi_width[4]), .A3(roi_width[8]), 
        .Y(n80) );
  NOR4X1_RVT U73 ( .A1(roi_width[2]), .A2(roi_width[1]), .A3(roi_width[3]), 
        .A4(roi_width[5]), .Y(n79) );
  NOR4X1_RVT U74 ( .A1(roi_width[6]), .A2(roi_width[7]), .A3(roi_width[9]), 
        .A4(roi_width[10]), .Y(n78) );
  NAND3X0_RVT U75 ( .A1(n80), .A2(n79), .A3(n78), .Y(n81) );
  AND4X1_RVT U76 ( .A1(in_roi), .A2(n83), .A3(n82), .A4(n81), .Y(sel_pixel) );
  NOR4X1_RVT U77 ( .A1(u[9]), .A2(u[8]), .A3(u[7]), .A4(u[6]), .Y(n85) );
  NOR4X1_RVT U78 ( .A1(u[5]), .A2(u[4]), .A3(u[3]), .A4(u[2]), .Y(n84) );
  NAND3X0_RVT U79 ( .A1(sel_pixel), .A2(n85), .A3(n84), .Y(n86) );
  NOR4X1_RVT U80 ( .A1(u[0]), .A2(u[10]), .A3(u[1]), .A4(n86), .Y(out_sol) );
  NOR4X1_RVT U81 ( .A1(v[9]), .A2(v[8]), .A3(v[7]), .A4(v[6]), .Y(n88) );
  NOR4X1_RVT U82 ( .A1(v[5]), .A2(v[4]), .A3(v[3]), .A4(v[2]), .Y(n87) );
  NAND3X0_RVT U83 ( .A1(out_sol), .A2(n88), .A3(n87), .Y(n89) );
  NOR4X1_RVT U84 ( .A1(v[0]), .A2(v[10]), .A3(v[1]), .A4(n89), .Y(out_sof) );
  NAND4X0_RVT U85 ( .A1(n107), .A2(n106), .A3(n110), .A4(n121), .Y(n98) );
  OR2X1_RVT U86 ( .A1(n99), .A2(n98), .Y(n118) );
  INVX0_RVT U87 ( .A(n118), .Y(n103) );
  NAND2X0_RVT U88 ( .A1(n49), .A2(n103), .Y(n135) );
  OR2X1_RVT U89 ( .A1(n139), .A2(n135), .Y(n137) );
  AO22X1_RVT U90 ( .A1(resize_x2), .A2(u[8]), .A3(n142), .A4(u[7]), .Y(n90) );
  FADDX1_RVT U91 ( .A(n127), .B(n137), .CI(n90), .S(n166) );
  NAND3X0_RVT U92 ( .A1(n107), .A2(n106), .A3(n110), .Y(n115) );
  AO22X1_RVT U93 ( .A1(resize_x2), .A2(u[4]), .A3(n142), .A4(u[3]), .Y(n116)
         );
  NAND2X0_RVT U94 ( .A1(n115), .A2(n116), .Y(n91) );
  OA22X1_RVT U95 ( .A1(n92), .A2(n91), .A3(n98), .A4(n116), .Y(n114) );
  OAI22X1_RVT U96 ( .A1(n142), .A2(u[2]), .A3(resize_x2), .A4(u[1]), .Y(n93)
         );
  HADDX1_RVT U97 ( .A0(n93), .B0(n107), .SO(n95) );
  AO21X1_RVT U98 ( .A1(resize_x2), .A2(u[1]), .A3(u[0]), .Y(n94) );
  NAND3X0_RVT U99 ( .A1(n95), .A2(n106), .A3(n94), .Y(n97) );
  OR3X1_RVT U100 ( .A1(n95), .A2(n106), .A3(n94), .Y(n96) );
  NAND2X0_RVT U101 ( .A1(n97), .A2(n96), .Y(n113) );
  AO22X1_RVT U102 ( .A1(resize_x2), .A2(u[5]), .A3(n142), .A4(u[4]), .Y(n119)
         );
  NAND2X0_RVT U103 ( .A1(n99), .A2(n98), .Y(n100) );
  HADDX1_RVT U104 ( .A0(n119), .B0(n100), .SO(n105) );
  AO22X1_RVT U105 ( .A1(resize_x2), .A2(u[6]), .A3(n142), .A4(u[5]), .Y(n123)
         );
  NAND2X0_RVT U106 ( .A1(n101), .A2(n123), .Y(n102) );
  AO22X1_RVT U107 ( .A1(n105), .A2(n104), .A3(n103), .A4(n102), .Y(n112) );
  AND2X1_RVT U108 ( .A1(n107), .A2(n106), .Y(n109) );
  AO22X1_RVT U109 ( .A1(resize_x2), .A2(u[3]), .A3(n142), .A4(u[2]), .Y(n108)
         );
  FADDX1_RVT U110 ( .A(n110), .B(n109), .CI(n108), .S(n111) );
  NAND4X0_RVT U111 ( .A1(n114), .A2(n113), .A3(n112), .A4(n111), .Y(n165) );
  INVX0_RVT U112 ( .A(n115), .Y(n117) );
  HADDX1_RVT U113 ( .A0(n117), .B0(n116), .SO(n120) );
  OA22X1_RVT U114 ( .A1(n121), .A2(n120), .A3(n119), .A4(n118), .Y(n131) );
  OA22X1_RVT U115 ( .A1(n142), .A2(u[7]), .A3(resize_x2), .A4(u[6]), .Y(n136)
         );
  INVX0_RVT U116 ( .A(n136), .Y(n122) );
  HADDX1_RVT U117 ( .A0(n135), .B0(n122), .SO(n124) );
  OA22X1_RVT U118 ( .A1(n125), .A2(n124), .A3(n123), .A4(n135), .Y(n130) );
  INVX0_RVT U119 ( .A(n137), .Y(n126) );
  NAND2X0_RVT U120 ( .A1(n127), .A2(n126), .Y(n132) );
  INVX0_RVT U121 ( .A(n132), .Y(n150) );
  NAND2X0_RVT U122 ( .A1(n152), .A2(n150), .Y(n157) );
  INVX0_RVT U123 ( .A(n157), .Y(n159) );
  NAND2X0_RVT U124 ( .A1(n147), .A2(u[9]), .Y(n128) );
  NAND3X0_RVT U125 ( .A1(n159), .A2(n155), .A3(n128), .Y(n129) );
  NAND3X0_RVT U126 ( .A1(n131), .A2(n130), .A3(n129), .Y(n164) );
  AO22X1_RVT U127 ( .A1(resize_x2), .A2(u[9]), .A3(n142), .A4(u[8]), .Y(n149)
         );
  NAND2X0_RVT U128 ( .A1(n132), .A2(n149), .Y(n133) );
  OA22X1_RVT U129 ( .A1(n134), .A2(n133), .A3(n157), .A4(n149), .Y(n141) );
  NAND2X0_RVT U130 ( .A1(n135), .A2(n136), .Y(n138) );
  OA22X1_RVT U131 ( .A1(n139), .A2(n138), .A3(n137), .A4(n136), .Y(n140) );
  AND2X1_RVT U132 ( .A1(n141), .A2(n140), .Y(n146) );
  AO22X1_RVT U133 ( .A1(resize_x2), .A2(u[10]), .A3(n142), .A4(u[9]), .Y(n156)
         );
  NAND2X0_RVT U134 ( .A1(n157), .A2(n156), .Y(n144) );
  OR2X1_RVT U135 ( .A1(n144), .A2(n143), .Y(n145) );
  AND2X1_RVT U136 ( .A1(n146), .A2(n145), .Y(n162) );
  AND2X1_RVT U137 ( .A1(n155), .A2(n159), .Y(n154) );
  INVX0_RVT U138 ( .A(roi_width[10]), .Y(n148) );
  AO221X1_RVT U139 ( .A1(u[10]), .A2(roi_width[10]), .A3(n148), .A4(n147), 
        .A5(resize_x2), .Y(n153) );
  HADDX1_RVT U140 ( .A0(n150), .B0(n149), .SO(n151) );
  OA22X1_RVT U141 ( .A1(n154), .A2(n153), .A3(n152), .A4(n151), .Y(n161) );
  INVX0_RVT U142 ( .A(n156), .Y(n158) );
  AO221X1_RVT U143 ( .A1(n159), .A2(n158), .A3(n157), .A4(n156), .A5(n155), 
        .Y(n160) );
  NAND4X0_RVT U144 ( .A1(n162), .A2(sel_pixel), .A3(n161), .A4(n160), .Y(n163)
         );
  NOR4X1_RVT U145 ( .A1(n166), .A2(n165), .A3(n164), .A4(n163), .Y(out_eol) );
  NAND4X0_RVT U146 ( .A1(n184), .A2(n183), .A3(n187), .A4(n198), .Y(n175) );
  OR2X1_RVT U147 ( .A1(n176), .A2(n175), .Y(n195) );
  INVX0_RVT U148 ( .A(n195), .Y(n180) );
  NAND2X0_RVT U149 ( .A1(n46), .A2(n180), .Y(n212) );
  OR2X1_RVT U150 ( .A1(n216), .A2(n212), .Y(n214) );
  AO22X1_RVT U151 ( .A1(resize_y2), .A2(v[8]), .A3(n219), .A4(v[7]), .Y(n167)
         );
  FADDX1_RVT U152 ( .A(n204), .B(n214), .CI(n167), .S(n243) );
  NAND3X0_RVT U153 ( .A1(n184), .A2(n183), .A3(n187), .Y(n192) );
  AO22X1_RVT U154 ( .A1(resize_y2), .A2(v[4]), .A3(n219), .A4(v[3]), .Y(n193)
         );
  NAND2X0_RVT U155 ( .A1(n192), .A2(n193), .Y(n168) );
  OA22X1_RVT U156 ( .A1(n169), .A2(n168), .A3(n175), .A4(n193), .Y(n191) );
  OAI22X1_RVT U157 ( .A1(n219), .A2(v[2]), .A3(resize_y2), .A4(v[1]), .Y(n170)
         );
  HADDX1_RVT U158 ( .A0(n170), .B0(n184), .SO(n172) );
  AO21X1_RVT U159 ( .A1(resize_y2), .A2(v[1]), .A3(v[0]), .Y(n171) );
  NAND3X0_RVT U160 ( .A1(n172), .A2(n183), .A3(n171), .Y(n174) );
  OR3X1_RVT U161 ( .A1(n172), .A2(n183), .A3(n171), .Y(n173) );
  NAND2X0_RVT U162 ( .A1(n174), .A2(n173), .Y(n190) );
  AO22X1_RVT U163 ( .A1(resize_y2), .A2(v[5]), .A3(n219), .A4(v[4]), .Y(n196)
         );
  NAND2X0_RVT U164 ( .A1(n176), .A2(n175), .Y(n177) );
  HADDX1_RVT U165 ( .A0(n196), .B0(n177), .SO(n182) );
  AO22X1_RVT U166 ( .A1(resize_y2), .A2(v[6]), .A3(n219), .A4(v[5]), .Y(n200)
         );
  NAND2X0_RVT U167 ( .A1(n178), .A2(n200), .Y(n179) );
  AO22X1_RVT U168 ( .A1(n182), .A2(n181), .A3(n180), .A4(n179), .Y(n189) );
  AND2X1_RVT U169 ( .A1(n184), .A2(n183), .Y(n186) );
  AO22X1_RVT U170 ( .A1(resize_y2), .A2(v[3]), .A3(n219), .A4(v[2]), .Y(n185)
         );
  FADDX1_RVT U171 ( .A(n187), .B(n186), .CI(n185), .S(n188) );
  NAND4X0_RVT U172 ( .A1(n191), .A2(n190), .A3(n189), .A4(n188), .Y(n242) );
  INVX0_RVT U173 ( .A(n192), .Y(n194) );
  HADDX1_RVT U174 ( .A0(n194), .B0(n193), .SO(n197) );
  OA22X1_RVT U175 ( .A1(n198), .A2(n197), .A3(n196), .A4(n195), .Y(n208) );
  OA22X1_RVT U176 ( .A1(n219), .A2(v[7]), .A3(resize_y2), .A4(v[6]), .Y(n213)
         );
  INVX0_RVT U177 ( .A(n213), .Y(n199) );
  HADDX1_RVT U178 ( .A0(n212), .B0(n199), .SO(n201) );
  OA22X1_RVT U179 ( .A1(n202), .A2(n201), .A3(n200), .A4(n212), .Y(n207) );
  INVX0_RVT U180 ( .A(n214), .Y(n203) );
  NAND2X0_RVT U181 ( .A1(n204), .A2(n203), .Y(n209) );
  INVX0_RVT U182 ( .A(n209), .Y(n227) );
  NAND2X0_RVT U183 ( .A1(n229), .A2(n227), .Y(n234) );
  INVX0_RVT U184 ( .A(n234), .Y(n236) );
  NAND2X0_RVT U185 ( .A1(n224), .A2(v[9]), .Y(n205) );
  NAND3X0_RVT U186 ( .A1(n236), .A2(n232), .A3(n205), .Y(n206) );
  NAND3X0_RVT U187 ( .A1(n208), .A2(n207), .A3(n206), .Y(n241) );
  AO22X1_RVT U188 ( .A1(resize_y2), .A2(v[9]), .A3(n219), .A4(v[8]), .Y(n226)
         );
  NAND2X0_RVT U189 ( .A1(n209), .A2(n226), .Y(n210) );
  OA22X1_RVT U190 ( .A1(n211), .A2(n210), .A3(n234), .A4(n226), .Y(n218) );
  NAND2X0_RVT U191 ( .A1(n212), .A2(n213), .Y(n215) );
  OA22X1_RVT U192 ( .A1(n216), .A2(n215), .A3(n214), .A4(n213), .Y(n217) );
  AND2X1_RVT U193 ( .A1(n218), .A2(n217), .Y(n223) );
  AO22X1_RVT U194 ( .A1(resize_y2), .A2(v[10]), .A3(n219), .A4(v[9]), .Y(n233)
         );
  NAND2X0_RVT U195 ( .A1(n234), .A2(n233), .Y(n221) );
  OR2X1_RVT U196 ( .A1(n221), .A2(n220), .Y(n222) );
  AND2X1_RVT U197 ( .A1(n223), .A2(n222), .Y(n239) );
  AND2X1_RVT U198 ( .A1(n232), .A2(n236), .Y(n231) );
  INVX0_RVT U199 ( .A(roi_height[10]), .Y(n225) );
  AO221X1_RVT U200 ( .A1(v[10]), .A2(roi_height[10]), .A3(n225), .A4(n224), 
        .A5(resize_y2), .Y(n230) );
  HADDX1_RVT U201 ( .A0(n227), .B0(n226), .SO(n228) );
  OA22X1_RVT U202 ( .A1(n231), .A2(n230), .A3(n229), .A4(n228), .Y(n238) );
  INVX0_RVT U203 ( .A(n233), .Y(n235) );
  AO221X1_RVT U204 ( .A1(n236), .A2(n235), .A3(n234), .A4(n233), .A5(n232), 
        .Y(n237) );
  NAND4X0_RVT U205 ( .A1(n239), .A2(out_eol), .A3(n238), .A4(n237), .Y(n240)
         );
  NOR4X1_RVT U206 ( .A1(n243), .A2(n242), .A3(n241), .A4(n240), .Y(out_eof) );
endmodule


module threshold_core ( y_gray, threshold_enable, threshold, pixel_thresh );
  input [7:0] y_gray;
  input [7:0] threshold;
  output [7:0] pixel_thresh;
  input threshold_enable;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
         n17, n18;

  INVX0_RVT U1 ( .A(threshold_enable), .Y(n18) );
  INVX0_RVT U2 ( .A(y_gray[7]), .Y(n16) );
  INVX0_RVT U3 ( .A(y_gray[6]), .Y(n13) );
  INVX0_RVT U4 ( .A(y_gray[5]), .Y(n11) );
  INVX0_RVT U5 ( .A(y_gray[4]), .Y(n9) );
  INVX0_RVT U6 ( .A(y_gray[3]), .Y(n7) );
  INVX0_RVT U7 ( .A(y_gray[2]), .Y(n5) );
  INVX0_RVT U8 ( .A(y_gray[1]), .Y(n3) );
  INVX0_RVT U9 ( .A(y_gray[0]), .Y(n2) );
  OA21X1_RVT U10 ( .A1(threshold[1]), .A2(n3), .A3(threshold[0]), .Y(n1) );
  AO22X1_RVT U11 ( .A1(threshold[1]), .A2(n3), .A3(n2), .A4(n1), .Y(n4) );
  AO222X1_RVT U12 ( .A1(threshold[2]), .A2(n5), .A3(threshold[2]), .A4(n4), 
        .A5(n5), .A6(n4), .Y(n6) );
  AO222X1_RVT U13 ( .A1(threshold[3]), .A2(n7), .A3(threshold[3]), .A4(n6), 
        .A5(n7), .A6(n6), .Y(n8) );
  AO222X1_RVT U14 ( .A1(threshold[4]), .A2(n9), .A3(threshold[4]), .A4(n8), 
        .A5(n9), .A6(n8), .Y(n10) );
  AO222X1_RVT U15 ( .A1(threshold[5]), .A2(n11), .A3(threshold[5]), .A4(n10), 
        .A5(n11), .A6(n10), .Y(n12) );
  AO222X1_RVT U16 ( .A1(threshold[6]), .A2(n13), .A3(threshold[6]), .A4(n12), 
        .A5(n13), .A6(n12), .Y(n14) );
  OR2X1_RVT U17 ( .A1(threshold[7]), .A2(n14), .Y(n15) );
  AOI221X1_RVT U18 ( .A1(n16), .A2(n15), .A3(threshold[7]), .A4(n14), .A5(n18), 
        .Y(n17) );
  AO21X1_RVT U19 ( .A1(y_gray[0]), .A2(n18), .A3(n17), .Y(pixel_thresh[0]) );
  AO21X1_RVT U20 ( .A1(y_gray[1]), .A2(n18), .A3(n17), .Y(pixel_thresh[1]) );
  AO21X1_RVT U21 ( .A1(y_gray[2]), .A2(n18), .A3(n17), .Y(pixel_thresh[2]) );
  AO21X1_RVT U22 ( .A1(y_gray[3]), .A2(n18), .A3(n17), .Y(pixel_thresh[3]) );
  AO21X1_RVT U23 ( .A1(y_gray[4]), .A2(n18), .A3(n17), .Y(pixel_thresh[4]) );
  AO21X1_RVT U24 ( .A1(y_gray[5]), .A2(n18), .A3(n17), .Y(pixel_thresh[5]) );
  AO21X1_RVT U25 ( .A1(y_gray[6]), .A2(n18), .A3(n17), .Y(pixel_thresh[6]) );
  AO21X1_RVT U26 ( .A1(y_gray[7]), .A2(n18), .A3(n17), .Y(pixel_thresh[7]) );
endmodule


module kuidamos_pixel_frontend ( clk, reset_n, pixel_r, pixel_g, pixel_b, 
        pixel_valid, in_sof, in_sol, in_eol, in_eof, cfg_in_width, 
        cfg_in_height, cfg_crop_enable, cfg_x_start, cfg_y_start, 
        cfg_crop_width, cfg_crop_height, cfg_resize_x2, cfg_resize_y2, 
        cfg_threshold_enable, cfg_threshold, pixel_out, pixel_out_valid, 
        out_sof, out_sol, out_eol, out_eof, cfg_error );
  input [7:0] pixel_r;
  input [7:0] pixel_g;
  input [7:0] pixel_b;
  input [10:0] cfg_in_width;
  input [10:0] cfg_in_height;
  input [10:0] cfg_x_start;
  input [10:0] cfg_y_start;
  input [10:0] cfg_crop_width;
  input [10:0] cfg_crop_height;
  input [7:0] cfg_threshold;
  output [7:0] pixel_out;
  input clk, reset_n, pixel_valid, in_sof, in_sol, in_eol, in_eof,
         cfg_crop_enable, cfg_resize_x2, cfg_resize_y2, cfg_threshold_enable;
  output pixel_out_valid, out_sof, out_sol, out_eol, out_eof, cfg_error;
  wire   frame_active_q, eff_crop_enable, cfg_crop_enable_q, eff_resize_x2,
         cfg_resize_x2_q, eff_resize_y2, cfg_resize_y2_q, eff_threshold_enable,
         cfg_threshold_enable_q, in_roi, sel_pixel, core_out_sof, core_out_sol,
         core_out_eol, core_out_eof, N260, N261, N262, N263, N264, N265, N266,
         N267, N268, N269, N270, N271, N272, N273, n95, n96, n97, n98, n99,
         n100, n101, n102, n103, n104, n105, n106, n107, n108, n109, n110,
         n111, n112, n113, n114, n115, n116, n117, n118, n119, n120, n121,
         n122, n123, n124, n125, n126, n127, n128, n129, n130, n131, n132,
         n133, n134, n135, n136, n137, n138, n139, n140, n141, n142, n143,
         n144, n145, n146, n147, n148, n149, n150, n151, n152, n153, n154,
         n155, n156, n157, n158, n159, n160, n161, n162, n163, n164, n165,
         n166, n167, n168, n169, n170, n171, n172, n173, n174, n175, n176,
         n177, n178, n179, n180, n181, n182, n183, n184, n185, n186, n187,
         n188, n189, n190, n191, n192, n193, n194, n195, intadd_0_CI,
         intadd_0_SUM_7_, intadd_0_SUM_6_, intadd_0_SUM_5_, intadd_0_SUM_4_,
         intadd_0_SUM_3_, intadd_0_SUM_2_, intadd_0_SUM_1_, intadd_0_SUM_0_,
         intadd_0_n8, intadd_0_n7, intadd_0_n6, intadd_0_n5, intadd_0_n4,
         intadd_0_n3, intadd_0_n2, intadd_0_n1, intadd_1_CI, intadd_1_SUM_7_,
         intadd_1_SUM_6_, intadd_1_SUM_5_, intadd_1_SUM_4_, intadd_1_SUM_3_,
         intadd_1_SUM_2_, intadd_1_SUM_1_, intadd_1_SUM_0_, intadd_1_n8,
         intadd_1_n7, intadd_1_n6, intadd_1_n5, intadd_1_n4, intadd_1_n3,
         intadd_1_n2, intadd_1_n1, n196, n197, n198, n199, n200, n201, n202,
         n203, n204, n205, n206, n207, n208, n209, n210, n211, n212, n213,
         n214, n215, n216, n217, n218, n219, n220, n221, n222, n223, n224,
         n225, n226, n227, n228, n229, n230, n231, n232, n233, n234, n235,
         n236, n237, n238, n239, n240, n241, n242, n243, n244, n245, n246,
         n247, n248, n249, n250, n251, n252, n253, n254, n255, n256, n257,
         n258, n259, n260, n261, n262, n263, n264, n265, n266, n267, n268,
         n269, n270, n271, n272, n273, n274, n275, n276, n277, n278, n279,
         n280, n281, n282, n283, n284, n285, n286, n287, n288, n289, n290,
         n291, n292, n293, n294, n295, n296, n297, n298, n299, n300, n301,
         n302, n303, n304, n305, n306, n307, n308, n309, n310, n311, n312,
         n313, n314, n315, n316, n317, n318, n319, n320, n321, n322, n323,
         n324, n325, n326, n327, n328, n329, n330, n331, n332, n333, n334,
         n335, n336, n337, n338, n339, n340, n341, n342, n343, n344, n345,
         n346, n347, n348, n349, n350, n351, n352, n353, n354, n355, n356,
         n357, n358, n359, n360, n361, n362, n363, n364, n365, n366, n367,
         n368, n369, n370, n371, n372, n373, n374, n375, n376, n377, n378,
         n379, n380, n381, n382, n383, n384, n385, n386, n387, n388, n389,
         n390, n391, n392, n393, n394, n395, n396, n397, n398, n399, n400,
         n401, n402, n403, n404, n405, n406, n407, n408, n409, n410, n411,
         n412, n413, n414, n415, n416, n417, n418, n419, n420, n421, n422,
         n423, n424, n425, n426, n427, n428, n429, n430, n431, n432, n433,
         n434, n435, n436, n437, n438, n439, n440, n441, n442, n443, n444,
         n445, n446, n447, n448, n449, n450, n451, n452, n453, n454, n455,
         n456, n457, n458, n459, n460, n461, n462, n463, n464, n465, n466,
         n467, n468, n469, n470, n471, n472, n473, n474, n475, n476, n477,
         n478, n479, n480, n481, n482, n483, SYNOPSYS_UNCONNECTED_1,
         SYNOPSYS_UNCONNECTED_2, SYNOPSYS_UNCONNECTED_3,
         SYNOPSYS_UNCONNECTED_4, SYNOPSYS_UNCONNECTED_5,
         SYNOPSYS_UNCONNECTED_6, SYNOPSYS_UNCONNECTED_7,
         SYNOPSYS_UNCONNECTED_8, SYNOPSYS_UNCONNECTED_9,
         SYNOPSYS_UNCONNECTED_10, SYNOPSYS_UNCONNECTED_11,
         SYNOPSYS_UNCONNECTED_12, SYNOPSYS_UNCONNECTED_13,
         SYNOPSYS_UNCONNECTED_14, SYNOPSYS_UNCONNECTED_15,
         SYNOPSYS_UNCONNECTED_16, SYNOPSYS_UNCONNECTED_17,
         SYNOPSYS_UNCONNECTED_18, SYNOPSYS_UNCONNECTED_19,
         SYNOPSYS_UNCONNECTED_20, SYNOPSYS_UNCONNECTED_21,
         SYNOPSYS_UNCONNECTED_22, SYNOPSYS_UNCONNECTED_23,
         SYNOPSYS_UNCONNECTED_24, SYNOPSYS_UNCONNECTED_25,
         SYNOPSYS_UNCONNECTED_26, SYNOPSYS_UNCONNECTED_27,
         SYNOPSYS_UNCONNECTED_28, SYNOPSYS_UNCONNECTED_29,
         SYNOPSYS_UNCONNECTED_30, SYNOPSYS_UNCONNECTED_31,
         SYNOPSYS_UNCONNECTED_32, SYNOPSYS_UNCONNECTED_33,
         SYNOPSYS_UNCONNECTED_34, SYNOPSYS_UNCONNECTED_35,
         SYNOPSYS_UNCONNECTED_36, SYNOPSYS_UNCONNECTED_37,
         SYNOPSYS_UNCONNECTED_38, SYNOPSYS_UNCONNECTED_39,
         SYNOPSYS_UNCONNECTED_40, SYNOPSYS_UNCONNECTED_41,
         SYNOPSYS_UNCONNECTED_42, SYNOPSYS_UNCONNECTED_43,
         SYNOPSYS_UNCONNECTED_44;
  wire   [10:0] curr_x;
  wire   [10:0] x_q;
  wire   [10:0] curr_y;
  wire   [10:0] y_q;
  wire   [10:0] eff_in_width;
  wire   [10:0] cfg_in_width_q;
  wire   [10:0] eff_in_height;
  wire   [10:0] cfg_in_height_q;
  wire   [10:0] eff_x_start;
  wire   [10:0] cfg_x_start_q;
  wire   [10:0] eff_y_start;
  wire   [10:0] cfg_y_start_q;
  wire   [10:0] eff_crop_width;
  wire   [10:0] cfg_crop_width_q;
  wire   [10:0] eff_crop_height;
  wire   [10:0] cfg_crop_height_q;
  wire   [7:0] eff_threshold;
  wire   [7:0] cfg_threshold_q;
  wire   [7:0] y_gray;
  wire   [10:0] roi_u;
  wire   [10:0] roi_v;
  wire   [10:0] roi_width;
  wire   [10:0] roi_height;
  wire   [7:0] pixel_thresh;

  grayscale_core u_grayscale_core ( .pixel_r(pixel_r), .pixel_g(pixel_g), 
        .pixel_b(pixel_b), .y_gray(y_gray) );
  crop_core u_crop_core ( .x(curr_x), .y(curr_y), .in_width(eff_in_width), 
        .in_height(eff_in_height), .crop_enable(eff_crop_enable), .x_start(
        eff_x_start), .y_start(eff_y_start), .crop_width(eff_crop_width), 
        .crop_height(eff_crop_height), .in_roi(in_roi), .u(roi_u), .v(roi_v), 
        .roi_width(roi_width), .roi_height(roi_height) );
  resize_nn_core u_resize_nn_core ( .in_roi(in_roi), .u(roi_u), .v(roi_v), 
        .roi_width(roi_width), .roi_height(roi_height), .resize_x2(
        eff_resize_x2), .resize_y2(eff_resize_y2), .out_width({
        SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2, SYNOPSYS_UNCONNECTED_3, 
        SYNOPSYS_UNCONNECTED_4, SYNOPSYS_UNCONNECTED_5, SYNOPSYS_UNCONNECTED_6, 
        SYNOPSYS_UNCONNECTED_7, SYNOPSYS_UNCONNECTED_8, SYNOPSYS_UNCONNECTED_9, 
        SYNOPSYS_UNCONNECTED_10, SYNOPSYS_UNCONNECTED_11}), .out_height({
        SYNOPSYS_UNCONNECTED_12, SYNOPSYS_UNCONNECTED_13, 
        SYNOPSYS_UNCONNECTED_14, SYNOPSYS_UNCONNECTED_15, 
        SYNOPSYS_UNCONNECTED_16, SYNOPSYS_UNCONNECTED_17, 
        SYNOPSYS_UNCONNECTED_18, SYNOPSYS_UNCONNECTED_19, 
        SYNOPSYS_UNCONNECTED_20, SYNOPSYS_UNCONNECTED_21, 
        SYNOPSYS_UNCONNECTED_22}), .sel_pixel(sel_pixel), .x_out({
        SYNOPSYS_UNCONNECTED_23, SYNOPSYS_UNCONNECTED_24, 
        SYNOPSYS_UNCONNECTED_25, SYNOPSYS_UNCONNECTED_26, 
        SYNOPSYS_UNCONNECTED_27, SYNOPSYS_UNCONNECTED_28, 
        SYNOPSYS_UNCONNECTED_29, SYNOPSYS_UNCONNECTED_30, 
        SYNOPSYS_UNCONNECTED_31, SYNOPSYS_UNCONNECTED_32, 
        SYNOPSYS_UNCONNECTED_33}), .y_out({SYNOPSYS_UNCONNECTED_34, 
        SYNOPSYS_UNCONNECTED_35, SYNOPSYS_UNCONNECTED_36, 
        SYNOPSYS_UNCONNECTED_37, SYNOPSYS_UNCONNECTED_38, 
        SYNOPSYS_UNCONNECTED_39, SYNOPSYS_UNCONNECTED_40, 
        SYNOPSYS_UNCONNECTED_41, SYNOPSYS_UNCONNECTED_42, 
        SYNOPSYS_UNCONNECTED_43, SYNOPSYS_UNCONNECTED_44}), .out_sof(
        core_out_sof), .out_sol(core_out_sol), .out_eol(core_out_eol), 
        .out_eof(core_out_eof) );
  threshold_core u_threshold_core ( .y_gray(y_gray), .threshold_enable(
        eff_threshold_enable), .threshold(eff_threshold), .pixel_thresh(
        pixel_thresh) );
  DFFX1_RVT cfg_error_reg ( .D(N273), .CLK(clk), .Q(cfg_error) );
  DFFX1_RVT frame_active_q_reg ( .D(n95), .CLK(clk), .Q(frame_active_q) );
  DFFX1_RVT x_q_reg_10_ ( .D(n96), .CLK(clk), .Q(x_q[10]) );
  DFFX1_RVT x_q_reg_9_ ( .D(n97), .CLK(clk), .Q(x_q[9]) );
  DFFX1_RVT x_q_reg_8_ ( .D(n98), .CLK(clk), .Q(x_q[8]) );
  DFFX1_RVT x_q_reg_7_ ( .D(n99), .CLK(clk), .Q(x_q[7]) );
  DFFX1_RVT x_q_reg_6_ ( .D(n100), .CLK(clk), .Q(x_q[6]) );
  DFFX1_RVT x_q_reg_5_ ( .D(n101), .CLK(clk), .Q(x_q[5]) );
  DFFX1_RVT x_q_reg_4_ ( .D(n102), .CLK(clk), .Q(x_q[4]) );
  DFFX1_RVT x_q_reg_3_ ( .D(n103), .CLK(clk), .Q(x_q[3]) );
  DFFX1_RVT x_q_reg_2_ ( .D(n104), .CLK(clk), .Q(x_q[2]) );
  DFFX1_RVT x_q_reg_1_ ( .D(n105), .CLK(clk), .Q(x_q[1]) );
  DFFX1_RVT x_q_reg_0_ ( .D(n106), .CLK(clk), .Q(x_q[0]) );
  DFFX1_RVT y_q_reg_10_ ( .D(n107), .CLK(clk), .Q(y_q[10]) );
  DFFX1_RVT y_q_reg_9_ ( .D(n108), .CLK(clk), .Q(y_q[9]) );
  DFFX1_RVT y_q_reg_8_ ( .D(n109), .CLK(clk), .Q(y_q[8]) );
  DFFX1_RVT y_q_reg_7_ ( .D(n110), .CLK(clk), .Q(y_q[7]) );
  DFFX1_RVT y_q_reg_6_ ( .D(n111), .CLK(clk), .Q(y_q[6]) );
  DFFX1_RVT y_q_reg_5_ ( .D(n112), .CLK(clk), .Q(y_q[5]) );
  DFFX1_RVT y_q_reg_4_ ( .D(n113), .CLK(clk), .Q(y_q[4]) );
  DFFX1_RVT y_q_reg_3_ ( .D(n114), .CLK(clk), .Q(y_q[3]) );
  DFFX1_RVT y_q_reg_2_ ( .D(n115), .CLK(clk), .Q(y_q[2]) );
  DFFX1_RVT y_q_reg_1_ ( .D(n116), .CLK(clk), .Q(y_q[1]) );
  DFFX1_RVT y_q_reg_0_ ( .D(n117), .CLK(clk), .Q(y_q[0]) );
  DFFX1_RVT cfg_in_width_q_reg_10_ ( .D(n184), .CLK(clk), .Q(
        cfg_in_width_q[10]) );
  DFFX1_RVT cfg_in_width_q_reg_9_ ( .D(n185), .CLK(clk), .Q(cfg_in_width_q[9]), 
        .QN(n478) );
  DFFX1_RVT cfg_in_width_q_reg_8_ ( .D(n186), .CLK(clk), .Q(cfg_in_width_q[8])
         );
  DFFX1_RVT cfg_in_width_q_reg_7_ ( .D(n187), .CLK(clk), .Q(cfg_in_width_q[7])
         );
  DFFX1_RVT cfg_in_width_q_reg_6_ ( .D(n188), .CLK(clk), .Q(cfg_in_width_q[6])
         );
  DFFX1_RVT cfg_in_width_q_reg_5_ ( .D(n189), .CLK(clk), .Q(cfg_in_width_q[5])
         );
  DFFX1_RVT cfg_in_width_q_reg_4_ ( .D(n190), .CLK(clk), .Q(cfg_in_width_q[4])
         );
  DFFX1_RVT cfg_in_width_q_reg_3_ ( .D(n191), .CLK(clk), .Q(cfg_in_width_q[3]), 
        .QN(n477) );
  DFFX1_RVT cfg_in_width_q_reg_2_ ( .D(n192), .CLK(clk), .Q(cfg_in_width_q[2])
         );
  DFFX1_RVT cfg_in_width_q_reg_1_ ( .D(n193), .CLK(clk), .Q(cfg_in_width_q[1])
         );
  DFFX1_RVT cfg_in_width_q_reg_0_ ( .D(n194), .CLK(clk), .Q(cfg_in_width_q[0]), 
        .QN(n479) );
  DFFX1_RVT cfg_in_height_q_reg_10_ ( .D(n173), .CLK(clk), .Q(
        cfg_in_height_q[10]), .QN(n480) );
  DFFX1_RVT cfg_in_height_q_reg_9_ ( .D(n174), .CLK(clk), .Q(
        cfg_in_height_q[9]), .QN(n482) );
  DFFX1_RVT cfg_in_height_q_reg_8_ ( .D(n175), .CLK(clk), .Q(
        cfg_in_height_q[8]) );
  DFFX1_RVT cfg_in_height_q_reg_7_ ( .D(n176), .CLK(clk), .Q(
        cfg_in_height_q[7]) );
  DFFX1_RVT cfg_in_height_q_reg_6_ ( .D(n177), .CLK(clk), .Q(
        cfg_in_height_q[6]) );
  DFFX1_RVT cfg_in_height_q_reg_5_ ( .D(n178), .CLK(clk), .Q(
        cfg_in_height_q[5]), .QN(n483) );
  DFFX1_RVT cfg_in_height_q_reg_4_ ( .D(n179), .CLK(clk), .Q(
        cfg_in_height_q[4]) );
  DFFX1_RVT cfg_in_height_q_reg_3_ ( .D(n180), .CLK(clk), .Q(
        cfg_in_height_q[3]) );
  DFFX1_RVT cfg_in_height_q_reg_2_ ( .D(n181), .CLK(clk), .Q(
        cfg_in_height_q[2]) );
  DFFX1_RVT cfg_in_height_q_reg_1_ ( .D(n182), .CLK(clk), .Q(
        cfg_in_height_q[1]) );
  DFFX1_RVT cfg_in_height_q_reg_0_ ( .D(n183), .CLK(clk), .Q(
        cfg_in_height_q[0]), .QN(n481) );
  DFFX1_RVT cfg_crop_enable_q_reg ( .D(n172), .CLK(clk), .Q(cfg_crop_enable_q)
         );
  DFFX1_RVT cfg_x_start_q_reg_10_ ( .D(n161), .CLK(clk), .Q(cfg_x_start_q[10])
         );
  DFFX1_RVT cfg_x_start_q_reg_9_ ( .D(n162), .CLK(clk), .Q(cfg_x_start_q[9])
         );
  DFFX1_RVT cfg_x_start_q_reg_8_ ( .D(n163), .CLK(clk), .Q(cfg_x_start_q[8])
         );
  DFFX1_RVT cfg_x_start_q_reg_7_ ( .D(n164), .CLK(clk), .Q(cfg_x_start_q[7])
         );
  DFFX1_RVT cfg_x_start_q_reg_6_ ( .D(n165), .CLK(clk), .Q(cfg_x_start_q[6])
         );
  DFFX1_RVT cfg_x_start_q_reg_5_ ( .D(n166), .CLK(clk), .Q(cfg_x_start_q[5])
         );
  DFFX1_RVT cfg_x_start_q_reg_4_ ( .D(n167), .CLK(clk), .Q(cfg_x_start_q[4])
         );
  DFFX1_RVT cfg_x_start_q_reg_3_ ( .D(n168), .CLK(clk), .Q(cfg_x_start_q[3])
         );
  DFFX1_RVT cfg_x_start_q_reg_2_ ( .D(n169), .CLK(clk), .Q(cfg_x_start_q[2])
         );
  DFFX1_RVT cfg_x_start_q_reg_1_ ( .D(n170), .CLK(clk), .Q(cfg_x_start_q[1])
         );
  DFFX1_RVT cfg_x_start_q_reg_0_ ( .D(n171), .CLK(clk), .Q(cfg_x_start_q[0])
         );
  DFFX1_RVT cfg_y_start_q_reg_10_ ( .D(n150), .CLK(clk), .Q(cfg_y_start_q[10])
         );
  DFFX1_RVT cfg_y_start_q_reg_9_ ( .D(n151), .CLK(clk), .Q(cfg_y_start_q[9])
         );
  DFFX1_RVT cfg_y_start_q_reg_8_ ( .D(n152), .CLK(clk), .Q(cfg_y_start_q[8])
         );
  DFFX1_RVT cfg_y_start_q_reg_7_ ( .D(n153), .CLK(clk), .Q(cfg_y_start_q[7])
         );
  DFFX1_RVT cfg_y_start_q_reg_6_ ( .D(n154), .CLK(clk), .Q(cfg_y_start_q[6])
         );
  DFFX1_RVT cfg_y_start_q_reg_5_ ( .D(n155), .CLK(clk), .Q(cfg_y_start_q[5])
         );
  DFFX1_RVT cfg_y_start_q_reg_4_ ( .D(n156), .CLK(clk), .Q(cfg_y_start_q[4])
         );
  DFFX1_RVT cfg_y_start_q_reg_3_ ( .D(n157), .CLK(clk), .Q(cfg_y_start_q[3])
         );
  DFFX1_RVT cfg_y_start_q_reg_2_ ( .D(n158), .CLK(clk), .Q(cfg_y_start_q[2])
         );
  DFFX1_RVT cfg_y_start_q_reg_1_ ( .D(n159), .CLK(clk), .Q(cfg_y_start_q[1])
         );
  DFFX1_RVT cfg_y_start_q_reg_0_ ( .D(n160), .CLK(clk), .Q(cfg_y_start_q[0])
         );
  DFFX1_RVT cfg_crop_width_q_reg_10_ ( .D(n139), .CLK(clk), .Q(
        cfg_crop_width_q[10]) );
  DFFX1_RVT cfg_crop_width_q_reg_9_ ( .D(n140), .CLK(clk), .Q(
        cfg_crop_width_q[9]) );
  DFFX1_RVT cfg_crop_width_q_reg_8_ ( .D(n141), .CLK(clk), .Q(
        cfg_crop_width_q[8]) );
  DFFX1_RVT cfg_crop_width_q_reg_7_ ( .D(n142), .CLK(clk), .Q(
        cfg_crop_width_q[7]) );
  DFFX1_RVT cfg_crop_width_q_reg_6_ ( .D(n143), .CLK(clk), .Q(
        cfg_crop_width_q[6]) );
  DFFX1_RVT cfg_crop_width_q_reg_5_ ( .D(n144), .CLK(clk), .Q(
        cfg_crop_width_q[5]) );
  DFFX1_RVT cfg_crop_width_q_reg_4_ ( .D(n145), .CLK(clk), .Q(
        cfg_crop_width_q[4]) );
  DFFX1_RVT cfg_crop_width_q_reg_3_ ( .D(n146), .CLK(clk), .Q(
        cfg_crop_width_q[3]) );
  DFFX1_RVT cfg_crop_width_q_reg_2_ ( .D(n147), .CLK(clk), .Q(
        cfg_crop_width_q[2]) );
  DFFX1_RVT cfg_crop_width_q_reg_1_ ( .D(n148), .CLK(clk), .Q(
        cfg_crop_width_q[1]) );
  DFFX1_RVT cfg_crop_width_q_reg_0_ ( .D(n149), .CLK(clk), .Q(
        cfg_crop_width_q[0]) );
  DFFX1_RVT cfg_crop_height_q_reg_10_ ( .D(n128), .CLK(clk), .Q(
        cfg_crop_height_q[10]) );
  DFFX1_RVT cfg_crop_height_q_reg_9_ ( .D(n129), .CLK(clk), .Q(
        cfg_crop_height_q[9]) );
  DFFX1_RVT cfg_crop_height_q_reg_8_ ( .D(n130), .CLK(clk), .Q(
        cfg_crop_height_q[8]) );
  DFFX1_RVT cfg_crop_height_q_reg_7_ ( .D(n131), .CLK(clk), .Q(
        cfg_crop_height_q[7]) );
  DFFX1_RVT cfg_crop_height_q_reg_6_ ( .D(n132), .CLK(clk), .Q(
        cfg_crop_height_q[6]) );
  DFFX1_RVT cfg_crop_height_q_reg_5_ ( .D(n133), .CLK(clk), .Q(
        cfg_crop_height_q[5]) );
  DFFX1_RVT cfg_crop_height_q_reg_4_ ( .D(n134), .CLK(clk), .Q(
        cfg_crop_height_q[4]) );
  DFFX1_RVT cfg_crop_height_q_reg_3_ ( .D(n135), .CLK(clk), .Q(
        cfg_crop_height_q[3]) );
  DFFX1_RVT cfg_crop_height_q_reg_2_ ( .D(n136), .CLK(clk), .Q(
        cfg_crop_height_q[2]) );
  DFFX1_RVT cfg_crop_height_q_reg_1_ ( .D(n137), .CLK(clk), .Q(
        cfg_crop_height_q[1]) );
  DFFX1_RVT cfg_crop_height_q_reg_0_ ( .D(n138), .CLK(clk), .Q(
        cfg_crop_height_q[0]) );
  DFFX1_RVT cfg_resize_x2_q_reg ( .D(n127), .CLK(clk), .Q(cfg_resize_x2_q) );
  DFFX1_RVT cfg_resize_y2_q_reg ( .D(n126), .CLK(clk), .Q(cfg_resize_y2_q) );
  DFFX1_RVT cfg_threshold_enable_q_reg ( .D(n125), .CLK(clk), .Q(
        cfg_threshold_enable_q) );
  DFFX1_RVT cfg_threshold_q_reg_7_ ( .D(n118), .CLK(clk), .Q(
        cfg_threshold_q[7]) );
  DFFX1_RVT cfg_threshold_q_reg_6_ ( .D(n119), .CLK(clk), .Q(
        cfg_threshold_q[6]) );
  DFFX1_RVT cfg_threshold_q_reg_5_ ( .D(n120), .CLK(clk), .Q(
        cfg_threshold_q[5]) );
  DFFX1_RVT cfg_threshold_q_reg_4_ ( .D(n121), .CLK(clk), .Q(
        cfg_threshold_q[4]) );
  DFFX1_RVT cfg_threshold_q_reg_3_ ( .D(n122), .CLK(clk), .Q(
        cfg_threshold_q[3]) );
  DFFX1_RVT cfg_threshold_q_reg_2_ ( .D(n123), .CLK(clk), .Q(
        cfg_threshold_q[2]) );
  DFFX1_RVT cfg_threshold_q_reg_1_ ( .D(n124), .CLK(clk), .Q(
        cfg_threshold_q[1]) );
  DFFX1_RVT cfg_threshold_q_reg_0_ ( .D(n195), .CLK(clk), .Q(
        cfg_threshold_q[0]) );
  DFFX1_RVT pixel_out_reg_7_ ( .D(N267), .CLK(clk), .Q(pixel_out[7]) );
  DFFX1_RVT pixel_out_reg_6_ ( .D(N266), .CLK(clk), .Q(pixel_out[6]) );
  DFFX1_RVT pixel_out_reg_5_ ( .D(N265), .CLK(clk), .Q(pixel_out[5]) );
  DFFX1_RVT pixel_out_reg_4_ ( .D(N264), .CLK(clk), .Q(pixel_out[4]) );
  DFFX1_RVT pixel_out_reg_3_ ( .D(N263), .CLK(clk), .Q(pixel_out[3]) );
  DFFX1_RVT pixel_out_reg_2_ ( .D(N262), .CLK(clk), .Q(pixel_out[2]) );
  DFFX1_RVT pixel_out_reg_1_ ( .D(N261), .CLK(clk), .Q(pixel_out[1]) );
  DFFX1_RVT pixel_out_reg_0_ ( .D(N260), .CLK(clk), .Q(pixel_out[0]) );
  DFFX1_RVT pixel_out_valid_reg ( .D(N268), .CLK(clk), .Q(pixel_out_valid) );
  DFFX1_RVT out_sof_reg ( .D(N269), .CLK(clk), .Q(out_sof) );
  DFFX1_RVT out_sol_reg ( .D(N270), .CLK(clk), .Q(out_sol) );
  DFFX1_RVT out_eol_reg ( .D(N271), .CLK(clk), .Q(out_eol) );
  DFFX1_RVT out_eof_reg ( .D(N272), .CLK(clk), .Q(out_eof) );
  FADDX1_RVT intadd_0_U9 ( .A(cfg_crop_width[2]), .B(cfg_x_start[2]), .CI(
        intadd_0_CI), .CO(intadd_0_n8), .S(intadd_0_SUM_0_) );
  FADDX1_RVT intadd_0_U8 ( .A(cfg_crop_width[3]), .B(cfg_x_start[3]), .CI(
        intadd_0_n8), .CO(intadd_0_n7), .S(intadd_0_SUM_1_) );
  FADDX1_RVT intadd_0_U7 ( .A(cfg_crop_width[4]), .B(cfg_x_start[4]), .CI(
        intadd_0_n7), .CO(intadd_0_n6), .S(intadd_0_SUM_2_) );
  FADDX1_RVT intadd_0_U6 ( .A(cfg_crop_width[5]), .B(cfg_x_start[5]), .CI(
        intadd_0_n6), .CO(intadd_0_n5), .S(intadd_0_SUM_3_) );
  FADDX1_RVT intadd_0_U5 ( .A(cfg_crop_width[6]), .B(cfg_x_start[6]), .CI(
        intadd_0_n5), .CO(intadd_0_n4), .S(intadd_0_SUM_4_) );
  FADDX1_RVT intadd_0_U4 ( .A(cfg_crop_width[7]), .B(cfg_x_start[7]), .CI(
        intadd_0_n4), .CO(intadd_0_n3), .S(intadd_0_SUM_5_) );
  FADDX1_RVT intadd_0_U3 ( .A(cfg_crop_width[8]), .B(cfg_x_start[8]), .CI(
        intadd_0_n3), .CO(intadd_0_n2), .S(intadd_0_SUM_6_) );
  FADDX1_RVT intadd_0_U2 ( .A(cfg_crop_width[9]), .B(cfg_x_start[9]), .CI(
        intadd_0_n2), .CO(intadd_0_n1), .S(intadd_0_SUM_7_) );
  FADDX1_RVT intadd_1_U9 ( .A(cfg_crop_height[2]), .B(cfg_y_start[2]), .CI(
        intadd_1_CI), .CO(intadd_1_n8), .S(intadd_1_SUM_0_) );
  FADDX1_RVT intadd_1_U8 ( .A(cfg_crop_height[3]), .B(cfg_y_start[3]), .CI(
        intadd_1_n8), .CO(intadd_1_n7), .S(intadd_1_SUM_1_) );
  FADDX1_RVT intadd_1_U7 ( .A(cfg_crop_height[4]), .B(cfg_y_start[4]), .CI(
        intadd_1_n7), .CO(intadd_1_n6), .S(intadd_1_SUM_2_) );
  FADDX1_RVT intadd_1_U6 ( .A(cfg_crop_height[5]), .B(cfg_y_start[5]), .CI(
        intadd_1_n6), .CO(intadd_1_n5), .S(intadd_1_SUM_3_) );
  FADDX1_RVT intadd_1_U5 ( .A(cfg_crop_height[6]), .B(cfg_y_start[6]), .CI(
        intadd_1_n5), .CO(intadd_1_n4), .S(intadd_1_SUM_4_) );
  FADDX1_RVT intadd_1_U4 ( .A(cfg_crop_height[7]), .B(cfg_y_start[7]), .CI(
        intadd_1_n4), .CO(intadd_1_n3), .S(intadd_1_SUM_5_) );
  FADDX1_RVT intadd_1_U3 ( .A(cfg_crop_height[8]), .B(cfg_y_start[8]), .CI(
        intadd_1_n3), .CO(intadd_1_n2), .S(intadd_1_SUM_6_) );
  FADDX1_RVT intadd_1_U2 ( .A(cfg_crop_height[9]), .B(cfg_y_start[9]), .CI(
        intadd_1_n2), .CO(intadd_1_n1), .S(intadd_1_SUM_7_) );
  AO22X2_RVT U312 ( .A1(n290), .A2(cfg_resize_y2), .A3(n293), .A4(
        cfg_resize_y2_q), .Y(eff_resize_y2) );
  AND3X2_RVT U313 ( .A1(reset_n), .A2(n310), .A3(n309), .Y(n476) );
  AO22X2_RVT U314 ( .A1(n290), .A2(cfg_resize_x2), .A3(n293), .A4(
        cfg_resize_x2_q), .Y(eff_resize_x2) );
  NBUFFX2_RVT U315 ( .A(n291), .Y(n296) );
  NBUFFX2_RVT U316 ( .A(n308), .Y(n304) );
  NBUFFX2_RVT U317 ( .A(n308), .Y(n306) );
  AND2X1_RVT U318 ( .A1(n283), .A2(sel_pixel), .Y(N268) );
  NAND2X0_RVT U319 ( .A1(pixel_valid), .A2(in_sof), .Y(n196) );
  INVX0_RVT U320 ( .A(n196), .Y(n291) );
  INVX0_RVT U321 ( .A(n291), .Y(n297) );
  NAND2X0_RVT U322 ( .A1(y_q[1]), .A2(n297), .Y(n378) );
  INVX0_RVT U323 ( .A(n378), .Y(curr_y[1]) );
  INVX0_RVT U324 ( .A(n296), .Y(n295) );
  AO22X1_RVT U325 ( .A1(n291), .A2(cfg_in_height[0]), .A3(n295), .A4(
        cfg_in_height_q[0]), .Y(eff_in_height[0]) );
  AO22X1_RVT U326 ( .A1(n296), .A2(cfg_in_height[6]), .A3(n295), .A4(
        cfg_in_height_q[6]), .Y(eff_in_height[6]) );
  NBUFFX2_RVT U327 ( .A(n296), .Y(n290) );
  INVX0_RVT U328 ( .A(n290), .Y(n310) );
  AO22X1_RVT U329 ( .A1(n296), .A2(cfg_in_width[7]), .A3(n310), .A4(
        cfg_in_width_q[7]), .Y(eff_in_width[7]) );
  AO22X1_RVT U330 ( .A1(n296), .A2(cfg_in_width[5]), .A3(n310), .A4(
        cfg_in_width_q[5]), .Y(eff_in_width[5]) );
  AO22X1_RVT U331 ( .A1(n296), .A2(cfg_in_width[6]), .A3(n310), .A4(
        cfg_in_width_q[6]), .Y(eff_in_width[6]) );
  AO22X1_RVT U332 ( .A1(n291), .A2(cfg_in_width[3]), .A3(n310), .A4(
        cfg_in_width_q[3]), .Y(eff_in_width[3]) );
  AO22X1_RVT U333 ( .A1(n291), .A2(cfg_in_width[2]), .A3(n295), .A4(
        cfg_in_width_q[2]), .Y(eff_in_width[2]) );
  NAND2X0_RVT U334 ( .A1(x_q[2]), .A2(n310), .Y(n325) );
  INVX0_RVT U335 ( .A(n325), .Y(curr_x[2]) );
  AO22X1_RVT U336 ( .A1(n296), .A2(cfg_in_width[10]), .A3(n295), .A4(
        cfg_in_width_q[10]), .Y(eff_in_width[10]) );
  AO22X1_RVT U337 ( .A1(n291), .A2(cfg_in_width[0]), .A3(n310), .A4(
        cfg_in_width_q[0]), .Y(eff_in_width[0]) );
  AO22X1_RVT U338 ( .A1(n291), .A2(cfg_in_width[1]), .A3(n310), .A4(
        cfg_in_width_q[1]), .Y(eff_in_width[1]) );
  AO22X1_RVT U339 ( .A1(n291), .A2(cfg_in_width[4]), .A3(n310), .A4(
        cfg_in_width_q[4]), .Y(eff_in_width[4]) );
  AO22X1_RVT U340 ( .A1(n290), .A2(cfg_in_height[9]), .A3(n295), .A4(
        cfg_in_height_q[9]), .Y(eff_in_height[9]) );
  NAND2X0_RVT U341 ( .A1(y_q[9]), .A2(n297), .Y(n407) );
  INVX0_RVT U342 ( .A(n407), .Y(curr_y[9]) );
  NBUFFX2_RVT U343 ( .A(n291), .Y(n294) );
  INVX0_RVT U344 ( .A(n294), .Y(n293) );
  AO22X1_RVT U345 ( .A1(n290), .A2(cfg_in_height[8]), .A3(n293), .A4(
        cfg_in_height_q[8]), .Y(eff_in_height[8]) );
  AO22X1_RVT U346 ( .A1(n290), .A2(cfg_in_height[7]), .A3(n295), .A4(
        cfg_in_height_q[7]), .Y(eff_in_height[7]) );
  AO22X1_RVT U347 ( .A1(n291), .A2(cfg_in_height[5]), .A3(n295), .A4(
        cfg_in_height_q[5]), .Y(eff_in_height[5]) );
  AO22X1_RVT U348 ( .A1(n291), .A2(cfg_in_height[1]), .A3(n295), .A4(
        cfg_in_height_q[1]), .Y(eff_in_height[1]) );
  AO22X1_RVT U349 ( .A1(n291), .A2(cfg_in_height[2]), .A3(n295), .A4(
        cfg_in_height_q[2]), .Y(eff_in_height[2]) );
  INVX0_RVT U350 ( .A(cfg_in_height[3]), .Y(n214) );
  INVX0_RVT U351 ( .A(cfg_in_height[4]), .Y(n216) );
  INVX0_RVT U352 ( .A(cfg_in_height[5]), .Y(n218) );
  INVX0_RVT U353 ( .A(cfg_in_height[6]), .Y(n220) );
  AND4X1_RVT U354 ( .A1(n214), .A2(n216), .A3(n218), .A4(n220), .Y(n200) );
  INVX0_RVT U355 ( .A(cfg_resize_y2), .Y(n263) );
  AO21X1_RVT U356 ( .A1(cfg_in_height[0]), .A2(n263), .A3(cfg_in_height[2]), 
        .Y(n197) );
  NOR4X1_RVT U357 ( .A1(cfg_in_height[1]), .A2(cfg_in_height[7]), .A3(
        cfg_in_height[8]), .A4(n197), .Y(n199) );
  INVX0_RVT U358 ( .A(cfg_in_height[9]), .Y(n262) );
  INVX0_RVT U359 ( .A(cfg_in_height[10]), .Y(n198) );
  NAND4X0_RVT U360 ( .A1(n200), .A2(n199), .A3(n262), .A4(n198), .Y(n205) );
  INVX0_RVT U361 ( .A(cfg_resize_x2), .Y(n267) );
  AOI21X1_RVT U362 ( .A1(n267), .A2(cfg_in_width[0]), .A3(cfg_in_width[10]), 
        .Y(n203) );
  INVX0_RVT U363 ( .A(cfg_in_width[5]), .Y(n241) );
  INVX0_RVT U364 ( .A(cfg_in_width[4]), .Y(n239) );
  INVX0_RVT U365 ( .A(cfg_in_width[3]), .Y(n237) );
  INVX0_RVT U366 ( .A(cfg_in_width[2]), .Y(n235) );
  AND4X1_RVT U367 ( .A1(n241), .A2(n239), .A3(n237), .A4(n235), .Y(n202) );
  INVX0_RVT U368 ( .A(cfg_in_width[9]), .Y(n260) );
  INVX0_RVT U369 ( .A(cfg_in_width[8]), .Y(n247) );
  INVX0_RVT U370 ( .A(cfg_in_width[7]), .Y(n245) );
  INVX0_RVT U371 ( .A(cfg_in_width[6]), .Y(n243) );
  AND4X1_RVT U372 ( .A1(n260), .A2(n247), .A3(n245), .A4(n243), .Y(n201) );
  INVX0_RVT U373 ( .A(cfg_in_width[1]), .Y(n232) );
  NAND4X0_RVT U374 ( .A1(n203), .A2(n202), .A3(n201), .A4(n232), .Y(n204) );
  AND2X1_RVT U375 ( .A1(n205), .A2(n204), .Y(n282) );
  INVX0_RVT U376 ( .A(cfg_crop_enable), .Y(n280) );
  NOR3X0_RVT U377 ( .A1(cfg_y_start[10]), .A2(cfg_crop_height[10]), .A3(
        intadd_1_n1), .Y(n254) );
  NAND2X0_RVT U378 ( .A1(n254), .A2(cfg_in_height[10]), .Y(n261) );
  NAND2X0_RVT U379 ( .A1(cfg_y_start[0]), .A2(cfg_crop_height[0]), .Y(n289) );
  INVX0_RVT U380 ( .A(cfg_y_start[1]), .Y(n288) );
  INVX0_RVT U381 ( .A(cfg_crop_height[1]), .Y(n287) );
  AO22X1_RVT U382 ( .A1(cfg_y_start[1]), .A2(cfg_crop_height[1]), .A3(n288), 
        .A4(n287), .Y(n211) );
  INVX0_RVT U383 ( .A(cfg_in_height[0]), .Y(n206) );
  OAI21X1_RVT U384 ( .A1(cfg_y_start[0]), .A2(cfg_crop_height[0]), .A3(n206), 
        .Y(n207) );
  NOR2X0_RVT U385 ( .A1(n207), .A2(n211), .Y(n210) );
  INVX0_RVT U386 ( .A(cfg_in_height[1]), .Y(n209) );
  NAND3X0_RVT U387 ( .A1(n211), .A2(n289), .A3(n207), .Y(n208) );
  OA221X1_RVT U388 ( .A1(n289), .A2(n211), .A3(n210), .A4(n209), .A5(n208), 
        .Y(n213) );
  INVX0_RVT U389 ( .A(cfg_in_height[2]), .Y(n212) );
  AO222X1_RVT U390 ( .A1(n213), .A2(intadd_1_SUM_0_), .A3(n213), .A4(n212), 
        .A5(intadd_1_SUM_0_), .A6(n212), .Y(n215) );
  AO222X1_RVT U391 ( .A1(n215), .A2(intadd_1_SUM_1_), .A3(n215), .A4(n214), 
        .A5(intadd_1_SUM_1_), .A6(n214), .Y(n217) );
  AO222X1_RVT U392 ( .A1(n217), .A2(intadd_1_SUM_2_), .A3(n217), .A4(n216), 
        .A5(intadd_1_SUM_2_), .A6(n216), .Y(n219) );
  AO222X1_RVT U393 ( .A1(n219), .A2(intadd_1_SUM_3_), .A3(n219), .A4(n218), 
        .A5(intadd_1_SUM_3_), .A6(n218), .Y(n221) );
  AO222X1_RVT U394 ( .A1(n221), .A2(intadd_1_SUM_4_), .A3(n221), .A4(n220), 
        .A5(intadd_1_SUM_4_), .A6(n220), .Y(n223) );
  INVX0_RVT U395 ( .A(cfg_in_height[7]), .Y(n222) );
  AO222X1_RVT U396 ( .A1(n223), .A2(intadd_1_SUM_5_), .A3(n223), .A4(n222), 
        .A5(intadd_1_SUM_5_), .A6(n222), .Y(n225) );
  INVX0_RVT U397 ( .A(cfg_in_height[8]), .Y(n224) );
  AO222X1_RVT U398 ( .A1(n225), .A2(intadd_1_SUM_6_), .A3(n225), .A4(n224), 
        .A5(intadd_1_SUM_6_), .A6(n224), .Y(n226) );
  AND2X1_RVT U399 ( .A1(n261), .A2(n226), .Y(n228) );
  OR2X1_RVT U400 ( .A1(n262), .A2(intadd_1_SUM_7_), .Y(n227) );
  AND2X1_RVT U401 ( .A1(n228), .A2(n227), .Y(n278) );
  NOR3X0_RVT U402 ( .A1(cfg_x_start[10]), .A2(cfg_crop_width[10]), .A3(
        intadd_0_n1), .Y(n255) );
  NAND2X0_RVT U403 ( .A1(cfg_in_width[10]), .A2(n255), .Y(n259) );
  NAND2X0_RVT U404 ( .A1(cfg_crop_width[0]), .A2(cfg_x_start[0]), .Y(n286) );
  INVX0_RVT U405 ( .A(cfg_x_start[1]), .Y(n285) );
  INVX0_RVT U406 ( .A(cfg_crop_width[1]), .Y(n284) );
  AO22X1_RVT U407 ( .A1(cfg_x_start[1]), .A2(cfg_crop_width[1]), .A3(n285), 
        .A4(n284), .Y(n234) );
  INVX0_RVT U408 ( .A(cfg_in_width[0]), .Y(n229) );
  OAI21X1_RVT U409 ( .A1(cfg_crop_width[0]), .A2(cfg_x_start[0]), .A3(n229), 
        .Y(n230) );
  NOR2X0_RVT U410 ( .A1(n230), .A2(n234), .Y(n233) );
  NAND3X0_RVT U411 ( .A1(n234), .A2(n286), .A3(n230), .Y(n231) );
  OA221X1_RVT U412 ( .A1(n286), .A2(n234), .A3(n233), .A4(n232), .A5(n231), 
        .Y(n236) );
  AO222X1_RVT U413 ( .A1(intadd_0_SUM_0_), .A2(n236), .A3(intadd_0_SUM_0_), 
        .A4(n235), .A5(n236), .A6(n235), .Y(n238) );
  AO222X1_RVT U414 ( .A1(intadd_0_SUM_1_), .A2(n238), .A3(intadd_0_SUM_1_), 
        .A4(n237), .A5(n238), .A6(n237), .Y(n240) );
  AO222X1_RVT U415 ( .A1(intadd_0_SUM_2_), .A2(n240), .A3(intadd_0_SUM_2_), 
        .A4(n239), .A5(n240), .A6(n239), .Y(n242) );
  AO222X1_RVT U416 ( .A1(intadd_0_SUM_3_), .A2(n242), .A3(intadd_0_SUM_3_), 
        .A4(n241), .A5(n242), .A6(n241), .Y(n244) );
  AO222X1_RVT U417 ( .A1(intadd_0_SUM_4_), .A2(n244), .A3(intadd_0_SUM_4_), 
        .A4(n243), .A5(n244), .A6(n243), .Y(n246) );
  AO222X1_RVT U418 ( .A1(intadd_0_SUM_5_), .A2(n246), .A3(intadd_0_SUM_5_), 
        .A4(n245), .A5(n246), .A6(n245), .Y(n248) );
  AO222X1_RVT U419 ( .A1(intadd_0_SUM_6_), .A2(n248), .A3(intadd_0_SUM_6_), 
        .A4(n247), .A5(n248), .A6(n247), .Y(n249) );
  AND2X1_RVT U420 ( .A1(n259), .A2(n249), .Y(n251) );
  OR2X1_RVT U421 ( .A1(n260), .A2(intadd_0_SUM_7_), .Y(n250) );
  AND2X1_RVT U422 ( .A1(n251), .A2(n250), .Y(n277) );
  AOI22X1_RVT U423 ( .A1(cfg_crop_height[10]), .A2(intadd_1_n1), .A3(
        cfg_crop_width[10]), .A4(intadd_0_n1), .Y(n258) );
  OR2X1_RVT U424 ( .A1(cfg_crop_height[10]), .A2(intadd_1_n1), .Y(n253) );
  OR2X1_RVT U425 ( .A1(cfg_crop_width[10]), .A2(intadd_0_n1), .Y(n252) );
  AOI22X1_RVT U426 ( .A1(cfg_y_start[10]), .A2(n253), .A3(cfg_x_start[10]), 
        .A4(n252), .Y(n257) );
  OA22X1_RVT U427 ( .A1(cfg_in_width[10]), .A2(n255), .A3(n254), .A4(
        cfg_in_height[10]), .Y(n256) );
  NAND3X0_RVT U428 ( .A1(n258), .A2(n257), .A3(n256), .Y(n276) );
  NAND3X0_RVT U429 ( .A1(intadd_0_SUM_7_), .A2(n260), .A3(n259), .Y(n274) );
  NAND3X0_RVT U430 ( .A1(intadd_1_SUM_7_), .A2(n262), .A3(n261), .Y(n273) );
  AOI21X1_RVT U431 ( .A1(n263), .A2(cfg_crop_height[0]), .A3(
        cfg_crop_height[10]), .Y(n266) );
  NOR4X1_RVT U432 ( .A1(cfg_crop_height[3]), .A2(cfg_crop_height[2]), .A3(
        cfg_crop_height[4]), .A4(cfg_crop_height[5]), .Y(n265) );
  NOR4X1_RVT U433 ( .A1(cfg_crop_height[8]), .A2(cfg_crop_height[6]), .A3(
        cfg_crop_height[7]), .A4(cfg_crop_height[9]), .Y(n264) );
  NAND4X0_RVT U434 ( .A1(n266), .A2(n265), .A3(n264), .A4(n287), .Y(n272) );
  AOI21X1_RVT U435 ( .A1(n267), .A2(cfg_crop_width[0]), .A3(cfg_crop_width[10]), .Y(n270) );
  NOR4X1_RVT U436 ( .A1(cfg_crop_width[3]), .A2(cfg_crop_width[2]), .A3(
        cfg_crop_width[4]), .A4(cfg_crop_width[5]), .Y(n269) );
  NOR4X1_RVT U437 ( .A1(cfg_crop_width[8]), .A2(cfg_crop_width[6]), .A3(
        cfg_crop_width[7]), .A4(cfg_crop_width[9]), .Y(n268) );
  NAND4X0_RVT U438 ( .A1(n270), .A2(n269), .A3(n268), .A4(n284), .Y(n271) );
  NAND4X0_RVT U439 ( .A1(n274), .A2(n273), .A3(n272), .A4(n271), .Y(n275) );
  NOR4X1_RVT U440 ( .A1(n278), .A2(n277), .A3(n276), .A4(n275), .Y(n279) );
  OR2X1_RVT U441 ( .A1(n280), .A2(n279), .Y(n281) );
  AND2X1_RVT U442 ( .A1(n282), .A2(n281), .Y(n299) );
  NAND2X0_RVT U443 ( .A1(n296), .A2(n299), .Y(n300) );
  NAND2X0_RVT U444 ( .A1(pixel_valid), .A2(frame_active_q), .Y(n309) );
  INVX0_RVT U445 ( .A(reset_n), .Y(n298) );
  AO221X1_RVT U446 ( .A1(n300), .A2(in_sof), .A3(n300), .A4(n309), .A5(n298), 
        .Y(n417) );
  INVX0_RVT U447 ( .A(n417), .Y(n283) );
  NAND2X0_RVT U448 ( .A1(y_q[8]), .A2(n297), .Y(n438) );
  INVX0_RVT U449 ( .A(n438), .Y(curr_y[8]) );
  AND2X1_RVT U450 ( .A1(y_q[7]), .A2(n297), .Y(curr_y[7]) );
  NAND2X0_RVT U451 ( .A1(y_q[6]), .A2(n297), .Y(n433) );
  INVX0_RVT U452 ( .A(n433), .Y(curr_y[6]) );
  NAND2X0_RVT U453 ( .A1(y_q[4]), .A2(n297), .Y(n428) );
  INVX0_RVT U454 ( .A(n428), .Y(curr_y[4]) );
  NAND2X0_RVT U455 ( .A1(y_q[0]), .A2(n297), .Y(n419) );
  INVX0_RVT U456 ( .A(n419), .Y(curr_y[0]) );
  NAND2X0_RVT U457 ( .A1(y_q[2]), .A2(n297), .Y(n423) );
  INVX0_RVT U458 ( .A(n423), .Y(curr_y[2]) );
  AND2X1_RVT U459 ( .A1(y_q[3]), .A2(n293), .Y(curr_y[3]) );
  NAND2X0_RVT U460 ( .A1(x_q[9]), .A2(n297), .Y(n467) );
  INVX0_RVT U461 ( .A(n467), .Y(curr_x[9]) );
  NAND2X0_RVT U462 ( .A1(x_q[8]), .A2(n297), .Y(n364) );
  INVX0_RVT U463 ( .A(n364), .Y(curr_x[8]) );
  NAND2X0_RVT U464 ( .A1(x_q[7]), .A2(n297), .Y(n462) );
  INVX0_RVT U465 ( .A(n462), .Y(curr_x[7]) );
  AND2X1_RVT U466 ( .A1(x_q[6]), .A2(n310), .Y(curr_x[6]) );
  NAND2X0_RVT U467 ( .A1(x_q[5]), .A2(n310), .Y(n457) );
  INVX0_RVT U468 ( .A(n457), .Y(curr_x[5]) );
  NAND2X0_RVT U469 ( .A1(x_q[0]), .A2(n310), .Y(n448) );
  INVX0_RVT U470 ( .A(n448), .Y(curr_x[0]) );
  NAND2X0_RVT U471 ( .A1(x_q[1]), .A2(n310), .Y(n449) );
  INVX0_RVT U472 ( .A(n449), .Y(curr_x[1]) );
  NAND2X0_RVT U473 ( .A1(x_q[3]), .A2(n310), .Y(n452) );
  INVX0_RVT U474 ( .A(n452), .Y(curr_x[3]) );
  NAND2X0_RVT U475 ( .A1(x_q[10]), .A2(n310), .Y(n472) );
  INVX0_RVT U476 ( .A(n472), .Y(curr_x[10]) );
  NAND2X0_RVT U477 ( .A1(y_q[10]), .A2(n297), .Y(n444) );
  INVX0_RVT U478 ( .A(n444), .Y(curr_y[10]) );
  OAI222X1_RVT U479 ( .A1(n286), .A2(n285), .A3(n286), .A4(n284), .A5(n285), 
        .A6(n284), .Y(intadd_0_CI) );
  OAI222X1_RVT U480 ( .A1(n289), .A2(n288), .A3(n289), .A4(n287), .A5(n288), 
        .A6(n287), .Y(intadd_1_CI) );
  AND2X1_RVT U481 ( .A1(x_q[4]), .A2(n295), .Y(curr_x[4]) );
  AND2X1_RVT U482 ( .A1(y_q[5]), .A2(n196), .Y(curr_y[5]) );
  AO22X1_RVT U483 ( .A1(n296), .A2(cfg_in_width[8]), .A3(n310), .A4(
        cfg_in_width_q[8]), .Y(eff_in_width[8]) );
  AO22X1_RVT U484 ( .A1(n296), .A2(cfg_in_width[9]), .A3(n310), .A4(
        cfg_in_width_q[9]), .Y(eff_in_width[9]) );
  AO22X1_RVT U485 ( .A1(n291), .A2(cfg_in_height[3]), .A3(n295), .A4(
        cfg_in_height_q[3]), .Y(eff_in_height[3]) );
  AO22X1_RVT U486 ( .A1(n291), .A2(cfg_in_height[4]), .A3(n295), .A4(
        cfg_in_height_q[4]), .Y(eff_in_height[4]) );
  AO22X1_RVT U487 ( .A1(n290), .A2(cfg_in_height[10]), .A3(n295), .A4(
        cfg_in_height_q[10]), .Y(eff_in_height[10]) );
  AO22X1_RVT U488 ( .A1(n290), .A2(cfg_threshold[0]), .A3(n295), .A4(
        cfg_threshold_q[0]), .Y(eff_threshold[0]) );
  AO22X1_RVT U489 ( .A1(n290), .A2(cfg_threshold[1]), .A3(n295), .A4(
        cfg_threshold_q[1]), .Y(eff_threshold[1]) );
  AO22X1_RVT U490 ( .A1(n290), .A2(cfg_threshold[2]), .A3(n295), .A4(
        cfg_threshold_q[2]), .Y(eff_threshold[2]) );
  AO22X1_RVT U491 ( .A1(n290), .A2(cfg_threshold[3]), .A3(n293), .A4(
        cfg_threshold_q[3]), .Y(eff_threshold[3]) );
  AO22X1_RVT U492 ( .A1(n290), .A2(cfg_threshold[4]), .A3(n293), .A4(
        cfg_threshold_q[4]), .Y(eff_threshold[4]) );
  AO22X1_RVT U493 ( .A1(n290), .A2(cfg_threshold[5]), .A3(n293), .A4(
        cfg_threshold_q[5]), .Y(eff_threshold[5]) );
  AO22X1_RVT U494 ( .A1(n290), .A2(cfg_threshold[6]), .A3(n293), .A4(
        cfg_threshold_q[6]), .Y(eff_threshold[6]) );
  AO22X1_RVT U495 ( .A1(n290), .A2(cfg_threshold[7]), .A3(n293), .A4(
        cfg_threshold_q[7]), .Y(eff_threshold[7]) );
  AO22X1_RVT U496 ( .A1(n290), .A2(cfg_threshold_enable), .A3(n293), .A4(
        cfg_threshold_enable_q), .Y(eff_threshold_enable) );
  AO22X1_RVT U497 ( .A1(n290), .A2(cfg_crop_height[0]), .A3(n293), .A4(
        cfg_crop_height_q[0]), .Y(eff_crop_height[0]) );
  AO22X1_RVT U498 ( .A1(n290), .A2(cfg_crop_height[1]), .A3(n293), .A4(
        cfg_crop_height_q[1]), .Y(eff_crop_height[1]) );
  AO22X1_RVT U499 ( .A1(n290), .A2(cfg_crop_height[2]), .A3(n293), .A4(
        cfg_crop_height_q[2]), .Y(eff_crop_height[2]) );
  AO22X1_RVT U500 ( .A1(n296), .A2(cfg_crop_height[3]), .A3(n293), .A4(
        cfg_crop_height_q[3]), .Y(eff_crop_height[3]) );
  AO22X1_RVT U501 ( .A1(n296), .A2(cfg_crop_height[4]), .A3(n293), .A4(
        cfg_crop_height_q[4]), .Y(eff_crop_height[4]) );
  AO22X1_RVT U502 ( .A1(n296), .A2(cfg_crop_height[5]), .A3(n293), .A4(
        cfg_crop_height_q[5]), .Y(eff_crop_height[5]) );
  AO22X1_RVT U503 ( .A1(n296), .A2(cfg_crop_height[6]), .A3(n196), .A4(
        cfg_crop_height_q[6]), .Y(eff_crop_height[6]) );
  AO22X1_RVT U504 ( .A1(n296), .A2(cfg_crop_height[7]), .A3(n196), .A4(
        cfg_crop_height_q[7]), .Y(eff_crop_height[7]) );
  AO22X1_RVT U505 ( .A1(n296), .A2(cfg_crop_height[8]), .A3(n196), .A4(
        cfg_crop_height_q[8]), .Y(eff_crop_height[8]) );
  AO22X1_RVT U506 ( .A1(n296), .A2(cfg_crop_height[9]), .A3(n196), .A4(
        cfg_crop_height_q[9]), .Y(eff_crop_height[9]) );
  AO22X1_RVT U507 ( .A1(n296), .A2(cfg_crop_height[10]), .A3(n196), .A4(
        cfg_crop_height_q[10]), .Y(eff_crop_height[10]) );
  AO22X1_RVT U508 ( .A1(n296), .A2(cfg_crop_width[0]), .A3(n297), .A4(
        cfg_crop_width_q[0]), .Y(eff_crop_width[0]) );
  AO22X1_RVT U509 ( .A1(n296), .A2(cfg_crop_width[1]), .A3(n297), .A4(
        cfg_crop_width_q[1]), .Y(eff_crop_width[1]) );
  AO22X1_RVT U510 ( .A1(n296), .A2(cfg_crop_width[2]), .A3(n196), .A4(
        cfg_crop_width_q[2]), .Y(eff_crop_width[2]) );
  AO22X1_RVT U511 ( .A1(n296), .A2(cfg_crop_width[3]), .A3(n196), .A4(
        cfg_crop_width_q[3]), .Y(eff_crop_width[3]) );
  AO22X1_RVT U512 ( .A1(n296), .A2(cfg_crop_width[4]), .A3(n196), .A4(
        cfg_crop_width_q[4]), .Y(eff_crop_width[4]) );
  AO22X1_RVT U513 ( .A1(n296), .A2(cfg_crop_width[5]), .A3(n196), .A4(
        cfg_crop_width_q[5]), .Y(eff_crop_width[5]) );
  AO22X1_RVT U514 ( .A1(n296), .A2(cfg_crop_width[6]), .A3(n196), .A4(
        cfg_crop_width_q[6]), .Y(eff_crop_width[6]) );
  AO22X1_RVT U515 ( .A1(n296), .A2(cfg_crop_width[7]), .A3(n196), .A4(
        cfg_crop_width_q[7]), .Y(eff_crop_width[7]) );
  AO22X1_RVT U516 ( .A1(n296), .A2(cfg_crop_width[8]), .A3(n196), .A4(
        cfg_crop_width_q[8]), .Y(eff_crop_width[8]) );
  AO22X1_RVT U517 ( .A1(n296), .A2(cfg_crop_width[9]), .A3(n196), .A4(
        cfg_crop_width_q[9]), .Y(eff_crop_width[9]) );
  INVX0_RVT U518 ( .A(n291), .Y(n292) );
  AO22X1_RVT U519 ( .A1(n294), .A2(cfg_crop_width[10]), .A3(n292), .A4(
        cfg_crop_width_q[10]), .Y(eff_crop_width[10]) );
  AO22X1_RVT U520 ( .A1(n294), .A2(cfg_y_start[0]), .A3(n292), .A4(
        cfg_y_start_q[0]), .Y(eff_y_start[0]) );
  AO22X1_RVT U521 ( .A1(n294), .A2(cfg_y_start[1]), .A3(n292), .A4(
        cfg_y_start_q[1]), .Y(eff_y_start[1]) );
  AO22X1_RVT U522 ( .A1(n294), .A2(cfg_y_start[2]), .A3(n292), .A4(
        cfg_y_start_q[2]), .Y(eff_y_start[2]) );
  AO22X1_RVT U523 ( .A1(n294), .A2(cfg_y_start[3]), .A3(n292), .A4(
        cfg_y_start_q[3]), .Y(eff_y_start[3]) );
  AO22X1_RVT U524 ( .A1(n294), .A2(cfg_y_start[4]), .A3(n292), .A4(
        cfg_y_start_q[4]), .Y(eff_y_start[4]) );
  AO22X1_RVT U525 ( .A1(n294), .A2(cfg_y_start[5]), .A3(n292), .A4(
        cfg_y_start_q[5]), .Y(eff_y_start[5]) );
  AO22X1_RVT U526 ( .A1(n294), .A2(cfg_y_start[6]), .A3(n292), .A4(
        cfg_y_start_q[6]), .Y(eff_y_start[6]) );
  AO22X1_RVT U527 ( .A1(n294), .A2(cfg_y_start[7]), .A3(n292), .A4(
        cfg_y_start_q[7]), .Y(eff_y_start[7]) );
  AO22X1_RVT U528 ( .A1(n294), .A2(cfg_y_start[8]), .A3(n292), .A4(
        cfg_y_start_q[8]), .Y(eff_y_start[8]) );
  AO22X1_RVT U529 ( .A1(n294), .A2(cfg_y_start[9]), .A3(n292), .A4(
        cfg_y_start_q[9]), .Y(eff_y_start[9]) );
  AO22X1_RVT U530 ( .A1(n294), .A2(cfg_y_start[10]), .A3(n292), .A4(
        cfg_y_start_q[10]), .Y(eff_y_start[10]) );
  AO22X1_RVT U531 ( .A1(n294), .A2(cfg_x_start[0]), .A3(n292), .A4(
        cfg_x_start_q[0]), .Y(eff_x_start[0]) );
  AO22X1_RVT U532 ( .A1(n294), .A2(cfg_x_start[1]), .A3(n292), .A4(
        cfg_x_start_q[1]), .Y(eff_x_start[1]) );
  AO22X1_RVT U533 ( .A1(n294), .A2(cfg_x_start[2]), .A3(n292), .A4(
        cfg_x_start_q[2]), .Y(eff_x_start[2]) );
  AO22X1_RVT U534 ( .A1(n294), .A2(cfg_x_start[3]), .A3(n292), .A4(
        cfg_x_start_q[3]), .Y(eff_x_start[3]) );
  AO22X1_RVT U535 ( .A1(n294), .A2(cfg_x_start[4]), .A3(n292), .A4(
        cfg_x_start_q[4]), .Y(eff_x_start[4]) );
  AO22X1_RVT U536 ( .A1(n294), .A2(cfg_x_start[5]), .A3(n293), .A4(
        cfg_x_start_q[5]), .Y(eff_x_start[5]) );
  AO22X1_RVT U537 ( .A1(n296), .A2(cfg_x_start[6]), .A3(n295), .A4(
        cfg_x_start_q[6]), .Y(eff_x_start[6]) );
  AO22X1_RVT U538 ( .A1(n296), .A2(cfg_x_start[7]), .A3(n196), .A4(
        cfg_x_start_q[7]), .Y(eff_x_start[7]) );
  AO22X1_RVT U539 ( .A1(n296), .A2(cfg_x_start[8]), .A3(n310), .A4(
        cfg_x_start_q[8]), .Y(eff_x_start[8]) );
  AO22X1_RVT U540 ( .A1(n296), .A2(cfg_x_start[9]), .A3(n297), .A4(
        cfg_x_start_q[9]), .Y(eff_x_start[9]) );
  AO22X1_RVT U541 ( .A1(n296), .A2(cfg_x_start[10]), .A3(n297), .A4(
        cfg_x_start_q[10]), .Y(eff_x_start[10]) );
  AO22X1_RVT U542 ( .A1(n296), .A2(cfg_crop_enable), .A3(n297), .A4(
        cfg_crop_enable_q), .Y(eff_crop_enable) );
  NOR3X0_RVT U543 ( .A1(n299), .A2(n298), .A3(n297), .Y(N273) );
  AND2X1_RVT U544 ( .A1(N268), .A2(core_out_eof), .Y(N272) );
  AND2X1_RVT U545 ( .A1(N268), .A2(core_out_eol), .Y(N271) );
  AND2X1_RVT U546 ( .A1(N268), .A2(core_out_sol), .Y(N270) );
  AND2X1_RVT U547 ( .A1(N268), .A2(core_out_sof), .Y(N269) );
  AND2X1_RVT U548 ( .A1(N268), .A2(pixel_thresh[0]), .Y(N260) );
  AND2X1_RVT U549 ( .A1(N268), .A2(pixel_thresh[1]), .Y(N261) );
  AND2X1_RVT U550 ( .A1(N268), .A2(pixel_thresh[2]), .Y(N262) );
  AND2X1_RVT U551 ( .A1(N268), .A2(pixel_thresh[3]), .Y(N263) );
  AND2X1_RVT U552 ( .A1(N268), .A2(pixel_thresh[4]), .Y(N264) );
  AND2X1_RVT U553 ( .A1(N268), .A2(pixel_thresh[5]), .Y(N265) );
  AND2X1_RVT U554 ( .A1(N268), .A2(pixel_thresh[6]), .Y(N266) );
  AND2X1_RVT U555 ( .A1(N268), .A2(pixel_thresh[7]), .Y(N267) );
  NAND2X0_RVT U556 ( .A1(reset_n), .A2(n300), .Y(n301) );
  INVX0_RVT U557 ( .A(n301), .Y(n308) );
  AND2X1_RVT U558 ( .A1(reset_n), .A2(n301), .Y(n302) );
  NBUFFX2_RVT U559 ( .A(n302), .Y(n305) );
  NBUFFX2_RVT U560 ( .A(n305), .Y(n303) );
  AO22X1_RVT U561 ( .A1(n306), .A2(cfg_threshold_q[0]), .A3(n303), .A4(
        cfg_threshold[0]), .Y(n195) );
  NBUFFX2_RVT U562 ( .A(n305), .Y(n307) );
  AO22X1_RVT U563 ( .A1(cfg_in_width_q[0]), .A2(n306), .A3(cfg_in_width[0]), 
        .A4(n307), .Y(n194) );
  AO22X1_RVT U564 ( .A1(cfg_in_width_q[1]), .A2(n306), .A3(cfg_in_width[1]), 
        .A4(n307), .Y(n193) );
  AO22X1_RVT U565 ( .A1(cfg_in_width_q[2]), .A2(n308), .A3(cfg_in_width[2]), 
        .A4(n307), .Y(n192) );
  AO22X1_RVT U566 ( .A1(cfg_in_width_q[3]), .A2(n306), .A3(cfg_in_width[3]), 
        .A4(n307), .Y(n191) );
  AO22X1_RVT U567 ( .A1(cfg_in_width_q[4]), .A2(n306), .A3(cfg_in_width[4]), 
        .A4(n307), .Y(n190) );
  AO22X1_RVT U568 ( .A1(cfg_in_width_q[5]), .A2(n306), .A3(cfg_in_width[5]), 
        .A4(n307), .Y(n189) );
  AO22X1_RVT U569 ( .A1(cfg_in_width_q[6]), .A2(n308), .A3(cfg_in_width[6]), 
        .A4(n307), .Y(n188) );
  AO22X1_RVT U570 ( .A1(cfg_in_width_q[7]), .A2(n306), .A3(cfg_in_width[7]), 
        .A4(n307), .Y(n187) );
  AO22X1_RVT U571 ( .A1(cfg_in_width_q[8]), .A2(n306), .A3(cfg_in_width[8]), 
        .A4(n307), .Y(n186) );
  AO22X1_RVT U572 ( .A1(cfg_in_width_q[9]), .A2(n306), .A3(cfg_in_width[9]), 
        .A4(n307), .Y(n185) );
  AO22X1_RVT U573 ( .A1(cfg_in_width_q[10]), .A2(n306), .A3(cfg_in_width[10]), 
        .A4(n307), .Y(n184) );
  AO22X1_RVT U574 ( .A1(cfg_in_height[0]), .A2(n305), .A3(cfg_in_height_q[0]), 
        .A4(n304), .Y(n183) );
  AO22X1_RVT U575 ( .A1(cfg_in_height[1]), .A2(n302), .A3(cfg_in_height_q[1]), 
        .A4(n304), .Y(n182) );
  AO22X1_RVT U576 ( .A1(cfg_in_height[2]), .A2(n302), .A3(cfg_in_height_q[2]), 
        .A4(n304), .Y(n181) );
  AO22X1_RVT U577 ( .A1(cfg_in_height[3]), .A2(n302), .A3(cfg_in_height_q[3]), 
        .A4(n304), .Y(n180) );
  AO22X1_RVT U578 ( .A1(cfg_in_height[4]), .A2(n302), .A3(cfg_in_height_q[4]), 
        .A4(n304), .Y(n179) );
  AO22X1_RVT U579 ( .A1(cfg_in_height[5]), .A2(n302), .A3(cfg_in_height_q[5]), 
        .A4(n304), .Y(n178) );
  AO22X1_RVT U580 ( .A1(cfg_in_height[6]), .A2(n302), .A3(cfg_in_height_q[6]), 
        .A4(n304), .Y(n177) );
  AO22X1_RVT U581 ( .A1(cfg_in_height[7]), .A2(n302), .A3(cfg_in_height_q[7]), 
        .A4(n304), .Y(n176) );
  AO22X1_RVT U582 ( .A1(cfg_in_height[8]), .A2(n305), .A3(cfg_in_height_q[8]), 
        .A4(n304), .Y(n175) );
  AO22X1_RVT U583 ( .A1(cfg_in_height[9]), .A2(n305), .A3(cfg_in_height_q[9]), 
        .A4(n304), .Y(n174) );
  AO22X1_RVT U584 ( .A1(cfg_in_height[10]), .A2(n305), .A3(cfg_in_height_q[10]), .A4(n304), .Y(n173) );
  AO22X1_RVT U585 ( .A1(cfg_crop_enable), .A2(n305), .A3(n304), .A4(
        cfg_crop_enable_q), .Y(n172) );
  AO22X1_RVT U586 ( .A1(cfg_x_start[0]), .A2(n305), .A3(n304), .A4(
        cfg_x_start_q[0]), .Y(n171) );
  AO22X1_RVT U587 ( .A1(cfg_x_start[1]), .A2(n305), .A3(n304), .A4(
        cfg_x_start_q[1]), .Y(n170) );
  AO22X1_RVT U588 ( .A1(n306), .A2(cfg_x_start_q[2]), .A3(n303), .A4(
        cfg_x_start[2]), .Y(n169) );
  AO22X1_RVT U589 ( .A1(n308), .A2(cfg_x_start_q[3]), .A3(n303), .A4(
        cfg_x_start[3]), .Y(n168) );
  AO22X1_RVT U590 ( .A1(n306), .A2(cfg_x_start_q[4]), .A3(n303), .A4(
        cfg_x_start[4]), .Y(n167) );
  AO22X1_RVT U591 ( .A1(n308), .A2(cfg_x_start_q[5]), .A3(n303), .A4(
        cfg_x_start[5]), .Y(n166) );
  AO22X1_RVT U592 ( .A1(n306), .A2(cfg_x_start_q[6]), .A3(n303), .A4(
        cfg_x_start[6]), .Y(n165) );
  AO22X1_RVT U593 ( .A1(n308), .A2(cfg_x_start_q[7]), .A3(n303), .A4(
        cfg_x_start[7]), .Y(n164) );
  AO22X1_RVT U594 ( .A1(n306), .A2(cfg_x_start_q[8]), .A3(n303), .A4(
        cfg_x_start[8]), .Y(n163) );
  AO22X1_RVT U595 ( .A1(n306), .A2(cfg_x_start_q[9]), .A3(n303), .A4(
        cfg_x_start[9]), .Y(n162) );
  AO22X1_RVT U596 ( .A1(cfg_x_start[10]), .A2(n303), .A3(n304), .A4(
        cfg_x_start_q[10]), .Y(n161) );
  AO22X1_RVT U597 ( .A1(cfg_y_start[0]), .A2(n303), .A3(n304), .A4(
        cfg_y_start_q[0]), .Y(n160) );
  AO22X1_RVT U598 ( .A1(cfg_y_start[1]), .A2(n305), .A3(n304), .A4(
        cfg_y_start_q[1]), .Y(n159) );
  AO22X1_RVT U599 ( .A1(n306), .A2(cfg_y_start_q[2]), .A3(n303), .A4(
        cfg_y_start[2]), .Y(n158) );
  AO22X1_RVT U600 ( .A1(n306), .A2(cfg_y_start_q[3]), .A3(n303), .A4(
        cfg_y_start[3]), .Y(n157) );
  AO22X1_RVT U601 ( .A1(n306), .A2(cfg_y_start_q[4]), .A3(n305), .A4(
        cfg_y_start[4]), .Y(n156) );
  AO22X1_RVT U602 ( .A1(n308), .A2(cfg_y_start_q[5]), .A3(n303), .A4(
        cfg_y_start[5]), .Y(n155) );
  AO22X1_RVT U603 ( .A1(n306), .A2(cfg_y_start_q[6]), .A3(n305), .A4(
        cfg_y_start[6]), .Y(n154) );
  AO22X1_RVT U604 ( .A1(n306), .A2(cfg_y_start_q[7]), .A3(n305), .A4(
        cfg_y_start[7]), .Y(n153) );
  AO22X1_RVT U605 ( .A1(n306), .A2(cfg_y_start_q[8]), .A3(n305), .A4(
        cfg_y_start[8]), .Y(n152) );
  AO22X1_RVT U606 ( .A1(n306), .A2(cfg_y_start_q[9]), .A3(n305), .A4(
        cfg_y_start[9]), .Y(n151) );
  AO22X1_RVT U607 ( .A1(cfg_y_start[10]), .A2(n305), .A3(n306), .A4(
        cfg_y_start_q[10]), .Y(n150) );
  AO22X1_RVT U608 ( .A1(cfg_crop_width[0]), .A2(n305), .A3(n306), .A4(
        cfg_crop_width_q[0]), .Y(n149) );
  AO22X1_RVT U609 ( .A1(cfg_crop_width[1]), .A2(n305), .A3(n306), .A4(
        cfg_crop_width_q[1]), .Y(n148) );
  AO22X1_RVT U610 ( .A1(cfg_crop_width[2]), .A2(n305), .A3(n306), .A4(
        cfg_crop_width_q[2]), .Y(n147) );
  AO22X1_RVT U611 ( .A1(cfg_crop_width[3]), .A2(n305), .A3(n304), .A4(
        cfg_crop_width_q[3]), .Y(n146) );
  AO22X1_RVT U612 ( .A1(cfg_crop_width[4]), .A2(n303), .A3(n304), .A4(
        cfg_crop_width_q[4]), .Y(n145) );
  AO22X1_RVT U613 ( .A1(cfg_crop_width[5]), .A2(n305), .A3(n304), .A4(
        cfg_crop_width_q[5]), .Y(n144) );
  AO22X1_RVT U614 ( .A1(cfg_crop_width[6]), .A2(n305), .A3(n304), .A4(
        cfg_crop_width_q[6]), .Y(n143) );
  AO22X1_RVT U615 ( .A1(cfg_crop_width[7]), .A2(n305), .A3(n304), .A4(
        cfg_crop_width_q[7]), .Y(n142) );
  AO22X1_RVT U616 ( .A1(cfg_crop_width[8]), .A2(n302), .A3(n304), .A4(
        cfg_crop_width_q[8]), .Y(n141) );
  AO22X1_RVT U617 ( .A1(cfg_crop_width[9]), .A2(n302), .A3(n304), .A4(
        cfg_crop_width_q[9]), .Y(n140) );
  AO22X1_RVT U618 ( .A1(cfg_crop_width[10]), .A2(n302), .A3(n304), .A4(
        cfg_crop_width_q[10]), .Y(n139) );
  AO22X1_RVT U619 ( .A1(cfg_crop_height[0]), .A2(n302), .A3(n304), .A4(
        cfg_crop_height_q[0]), .Y(n138) );
  AO22X1_RVT U620 ( .A1(cfg_crop_height[1]), .A2(n302), .A3(n304), .A4(
        cfg_crop_height_q[1]), .Y(n137) );
  AO22X1_RVT U621 ( .A1(cfg_crop_height[2]), .A2(n302), .A3(n304), .A4(
        cfg_crop_height_q[2]), .Y(n136) );
  AO22X1_RVT U622 ( .A1(cfg_crop_height[3]), .A2(n305), .A3(n304), .A4(
        cfg_crop_height_q[3]), .Y(n135) );
  AO22X1_RVT U623 ( .A1(cfg_crop_height[4]), .A2(n307), .A3(n304), .A4(
        cfg_crop_height_q[4]), .Y(n134) );
  AO22X1_RVT U624 ( .A1(cfg_crop_height[5]), .A2(n305), .A3(n308), .A4(
        cfg_crop_height_q[5]), .Y(n133) );
  AO22X1_RVT U625 ( .A1(cfg_crop_height[6]), .A2(n305), .A3(n308), .A4(
        cfg_crop_height_q[6]), .Y(n132) );
  AO22X1_RVT U626 ( .A1(cfg_crop_height[7]), .A2(n307), .A3(n304), .A4(
        cfg_crop_height_q[7]), .Y(n131) );
  AO22X1_RVT U627 ( .A1(cfg_crop_height[8]), .A2(n305), .A3(n308), .A4(
        cfg_crop_height_q[8]), .Y(n130) );
  AO22X1_RVT U628 ( .A1(cfg_crop_height[9]), .A2(n302), .A3(n308), .A4(
        cfg_crop_height_q[9]), .Y(n129) );
  AO22X1_RVT U629 ( .A1(cfg_crop_height[10]), .A2(n302), .A3(n308), .A4(
        cfg_crop_height_q[10]), .Y(n128) );
  AO22X1_RVT U630 ( .A1(cfg_resize_x2), .A2(n302), .A3(n308), .A4(
        cfg_resize_x2_q), .Y(n127) );
  AO22X1_RVT U631 ( .A1(cfg_resize_y2), .A2(n307), .A3(n304), .A4(
        cfg_resize_y2_q), .Y(n126) );
  AO22X1_RVT U632 ( .A1(n308), .A2(cfg_threshold_enable_q), .A3(n305), .A4(
        cfg_threshold_enable), .Y(n125) );
  AO22X1_RVT U633 ( .A1(n308), .A2(cfg_threshold_q[1]), .A3(n305), .A4(
        cfg_threshold[1]), .Y(n124) );
  AO22X1_RVT U634 ( .A1(n306), .A2(cfg_threshold_q[2]), .A3(n305), .A4(
        cfg_threshold[2]), .Y(n123) );
  AO22X1_RVT U635 ( .A1(n306), .A2(cfg_threshold_q[3]), .A3(n305), .A4(
        cfg_threshold[3]), .Y(n122) );
  AO22X1_RVT U636 ( .A1(n306), .A2(cfg_threshold_q[4]), .A3(n305), .A4(
        cfg_threshold[4]), .Y(n121) );
  AO22X1_RVT U637 ( .A1(n306), .A2(cfg_threshold_q[5]), .A3(n305), .A4(
        cfg_threshold[5]), .Y(n120) );
  AO22X1_RVT U638 ( .A1(n306), .A2(cfg_threshold_q[6]), .A3(n305), .A4(
        cfg_threshold[6]), .Y(n119) );
  AO22X1_RVT U639 ( .A1(n308), .A2(cfg_threshold_q[7]), .A3(n307), .A4(
        cfg_threshold[7]), .Y(n118) );
  INVX0_RVT U640 ( .A(eff_in_height[2]), .Y(n390) );
  OR2X1_RVT U641 ( .A1(eff_in_height[0]), .A2(eff_in_height[1]), .Y(n391) );
  INVX0_RVT U642 ( .A(n391), .Y(n392) );
  NAND2X0_RVT U643 ( .A1(n390), .A2(n392), .Y(n376) );
  FADDX1_RVT U644 ( .A(curr_y[3]), .B(eff_in_height[3]), .CI(n376), .S(n314)
         );
  AO22X1_RVT U645 ( .A1(curr_y[10]), .A2(n480), .A3(n444), .A4(
        eff_in_height[10]), .Y(n315) );
  NAND2X0_RVT U646 ( .A1(n315), .A2(eff_in_height[9]), .Y(n313) );
  OR3X1_RVT U647 ( .A1(n423), .A2(cfg_in_height_q[2]), .A3(n392), .Y(n312) );
  AO221X1_RVT U648 ( .A1(n419), .A2(cfg_in_height_q[1]), .A3(n419), .A4(n378), 
        .A5(n481), .Y(n311) );
  NAND4X0_RVT U649 ( .A1(n314), .A2(n313), .A3(n312), .A4(n311), .Y(n416) );
  NOR4X1_RVT U650 ( .A1(eff_in_height[4]), .A2(eff_in_height[3]), .A3(
        eff_in_height[2]), .A4(n391), .Y(n389) );
  INVX0_RVT U651 ( .A(n389), .Y(n388) );
  OA221X1_RVT U652 ( .A1(n389), .A2(n483), .A3(n388), .A4(eff_in_height[5]), 
        .A5(curr_y[5]), .Y(n415) );
  INVX0_RVT U653 ( .A(eff_in_height[5]), .Y(n387) );
  NAND2X0_RVT U654 ( .A1(n387), .A2(n389), .Y(n374) );
  OR2X1_RVT U655 ( .A1(n374), .A2(eff_in_height[6]), .Y(n399) );
  OR2X1_RVT U656 ( .A1(n399), .A2(eff_in_height[7]), .Y(n408) );
  INVX0_RVT U657 ( .A(n408), .Y(n402) );
  INVX0_RVT U658 ( .A(eff_in_height[8]), .Y(n409) );
  NAND2X0_RVT U659 ( .A1(n402), .A2(n409), .Y(n406) );
  OAI221X1_RVT U660 ( .A1(n315), .A2(n482), .A3(n315), .A4(curr_y[9]), .A5(
        n406), .Y(n320) );
  OA221X1_RVT U661 ( .A1(eff_in_height[9]), .A2(curr_y[9]), .A3(
        eff_in_height[9]), .A4(n315), .A5(curr_y[8]), .Y(n317) );
  INVX0_RVT U662 ( .A(eff_in_height[9]), .Y(n316) );
  AO221X1_RVT U663 ( .A1(n317), .A2(n316), .A3(n317), .A4(n407), .A5(n406), 
        .Y(n319) );
  NAND3X0_RVT U664 ( .A1(n408), .A2(eff_in_height[8]), .A3(n438), .Y(n318) );
  NAND3X0_RVT U665 ( .A1(n320), .A2(n319), .A3(n318), .Y(n414) );
  INVX0_RVT U666 ( .A(eff_in_width[4]), .Y(n350) );
  NOR4X1_RVT U667 ( .A1(eff_in_width[3]), .A2(eff_in_width[2]), .A3(
        eff_in_width[0]), .A4(eff_in_width[1]), .Y(n349) );
  NAND2X0_RVT U668 ( .A1(n350), .A2(n349), .Y(n351) );
  INVX0_RVT U669 ( .A(n351), .Y(n321) );
  OA221X1_RVT U670 ( .A1(n321), .A2(n457), .A3(n351), .A4(curr_x[5]), .A5(
        eff_in_width[5]), .Y(n373) );
  OR2X1_RVT U671 ( .A1(eff_in_width[0]), .A2(eff_in_width[1]), .Y(n331) );
  NAND2X0_RVT U672 ( .A1(curr_x[2]), .A2(n331), .Y(n324) );
  AND2X1_RVT U673 ( .A1(curr_x[9]), .A2(n478), .Y(n323) );
  INVX0_RVT U674 ( .A(eff_in_width[10]), .Y(n322) );
  AO22X1_RVT U675 ( .A1(curr_x[10]), .A2(cfg_in_width_q[10]), .A3(n472), .A4(
        n322), .Y(n354) );
  OA22X1_RVT U676 ( .A1(cfg_in_width_q[2]), .A2(n324), .A3(n323), .A4(n354), 
        .Y(n345) );
  INVX0_RVT U677 ( .A(n331), .Y(n326) );
  OA22X1_RVT U678 ( .A1(eff_in_width[2]), .A2(n326), .A3(n325), .A4(n326), .Y(
        n329) );
  NAND2X0_RVT U679 ( .A1(eff_in_width[2]), .A2(n326), .Y(n327) );
  MUX21X1_RVT U680 ( .A1(n327), .A2(eff_in_width[2]), .S0(curr_x[2]), .Y(n328)
         );
  NAND2X0_RVT U681 ( .A1(n329), .A2(n328), .Y(n330) );
  OA221X1_RVT U682 ( .A1(curr_x[0]), .A2(eff_in_width[0]), .A3(n448), .A4(n479), .A5(n330), .Y(n344) );
  INVX0_RVT U683 ( .A(eff_in_width[3]), .Y(n333) );
  OR2X1_RVT U684 ( .A1(eff_in_width[2]), .A2(n331), .Y(n332) );
  MUX41X1_RVT U685 ( .A1(eff_in_width[3]), .A3(n333), .A2(n477), .A4(
        cfg_in_width_q[3]), .S0(n332), .S1(curr_x[3]), .Y(n335) );
  FADDX1_RVT U686 ( .A(curr_x[1]), .B(eff_in_width[0]), .CI(eff_in_width[1]), 
        .S(n334) );
  AND2X1_RVT U687 ( .A1(n335), .A2(n334), .Y(n337) );
  INVX0_RVT U688 ( .A(eff_in_width[6]), .Y(n348) );
  OR2X1_RVT U689 ( .A1(eff_in_width[5]), .A2(n351), .Y(n352) );
  INVX0_RVT U690 ( .A(n352), .Y(n346) );
  NAND2X0_RVT U691 ( .A1(n348), .A2(n346), .Y(n338) );
  OR2X1_RVT U692 ( .A1(n338), .A2(curr_x[6]), .Y(n336) );
  AND2X1_RVT U693 ( .A1(n337), .A2(n336), .Y(n343) );
  OR2X1_RVT U694 ( .A1(eff_in_width[7]), .A2(n338), .Y(n363) );
  INVX0_RVT U695 ( .A(n363), .Y(n365) );
  NAND2X0_RVT U696 ( .A1(eff_in_width[7]), .A2(n338), .Y(n339) );
  HADDX1_RVT U697 ( .A0(curr_x[7]), .B0(n339), .SO(n341) );
  NAND2X0_RVT U698 ( .A1(curr_x[6]), .A2(n352), .Y(n340) );
  OA22X1_RVT U699 ( .A1(n365), .A2(n341), .A3(cfg_in_width_q[6]), .A4(n340), 
        .Y(n342) );
  NAND4X0_RVT U700 ( .A1(n345), .A2(n344), .A3(n343), .A4(n342), .Y(n372) );
  HADDX1_RVT U701 ( .A0(n346), .B0(curr_x[6]), .SO(n347) );
  OA22X1_RVT U702 ( .A1(n348), .A2(n347), .A3(curr_x[7]), .A4(n363), .Y(n361)
         );
  MUX41X1_RVT U703 ( .A1(n350), .A3(cfg_in_width_q[4]), .A2(eff_in_width[4]), 
        .A4(n350), .S0(curr_x[4]), .S1(n349), .Y(n360) );
  NAND2X0_RVT U704 ( .A1(curr_x[5]), .A2(n351), .Y(n353) );
  OA22X1_RVT U705 ( .A1(cfg_in_width_q[5]), .A2(n353), .A3(curr_x[5]), .A4(
        n352), .Y(n359) );
  NAND2X0_RVT U706 ( .A1(curr_x[8]), .A2(n363), .Y(n357) );
  INVX0_RVT U707 ( .A(n354), .Y(n355) );
  OA21X1_RVT U708 ( .A1(n355), .A2(eff_in_width[9]), .A3(curr_x[8]), .Y(n356)
         );
  OR2X1_RVT U709 ( .A1(eff_in_width[8]), .A2(n363), .Y(n362) );
  OA22X1_RVT U710 ( .A1(cfg_in_width_q[8]), .A2(n357), .A3(n356), .A4(n362), 
        .Y(n358) );
  NAND4X0_RVT U711 ( .A1(n361), .A2(n360), .A3(n359), .A4(n358), .Y(n371) );
  NAND2X0_RVT U712 ( .A1(curr_x[9]), .A2(n362), .Y(n368) );
  INVX0_RVT U713 ( .A(n368), .Y(n369) );
  OA21X1_RVT U714 ( .A1(curr_x[9]), .A2(n362), .A3(eff_in_width[9]), .Y(n367)
         );
  OA221X1_RVT U715 ( .A1(n365), .A2(n364), .A3(n363), .A4(curr_x[8]), .A5(
        eff_in_width[8]), .Y(n366) );
  AO221X1_RVT U716 ( .A1(n369), .A2(n478), .A3(n368), .A4(n367), .A5(n366), 
        .Y(n370) );
  NOR4X1_RVT U717 ( .A1(n373), .A2(n372), .A3(n371), .A4(n370), .Y(n421) );
  INVX0_RVT U718 ( .A(eff_in_height[6]), .Y(n375) );
  MUX41X1_RVT U719 ( .A1(eff_in_height[6]), .A3(n375), .A2(n375), .A4(
        cfg_in_height_q[6]), .S0(curr_y[6]), .S1(n374), .Y(n398) );
  OR2X1_RVT U720 ( .A1(eff_in_height[3]), .A2(n376), .Y(n377) );
  FADDX1_RVT U721 ( .A(curr_y[4]), .B(eff_in_height[4]), .CI(n377), .S(n396)
         );
  NAND3X0_RVT U722 ( .A1(n392), .A2(curr_y[2]), .A3(eff_in_height[2]), .Y(n384) );
  INVX0_RVT U723 ( .A(eff_in_height[0]), .Y(n379) );
  OA22X1_RVT U724 ( .A1(eff_in_height[1]), .A2(n379), .A3(eff_in_height[1]), 
        .A4(n378), .Y(n382) );
  NAND2X0_RVT U725 ( .A1(eff_in_height[1]), .A2(n379), .Y(n380) );
  MUX21X1_RVT U726 ( .A1(n380), .A2(n481), .S0(curr_y[1]), .Y(n381) );
  NAND2X0_RVT U727 ( .A1(n382), .A2(n381), .Y(n383) );
  AND2X1_RVT U728 ( .A1(n384), .A2(n383), .Y(n386) );
  OR2X1_RVT U729 ( .A1(eff_in_height[0]), .A2(curr_y[0]), .Y(n385) );
  AND2X1_RVT U730 ( .A1(n386), .A2(n385), .Y(n395) );
  AO221X1_RVT U731 ( .A1(n389), .A2(eff_in_height[5]), .A3(n388), .A4(n387), 
        .A5(curr_y[5]), .Y(n394) );
  AO221X1_RVT U732 ( .A1(n392), .A2(eff_in_height[2]), .A3(n391), .A4(n390), 
        .A5(curr_y[2]), .Y(n393) );
  AND4X1_RVT U733 ( .A1(n396), .A2(n395), .A3(n394), .A4(n393), .Y(n397) );
  AND2X1_RVT U734 ( .A1(n398), .A2(n397), .Y(n405) );
  NAND2X0_RVT U735 ( .A1(n399), .A2(eff_in_height[7]), .Y(n401) );
  NAND2X0_RVT U736 ( .A1(n401), .A2(curr_y[7]), .Y(n400) );
  OA221X1_RVT U737 ( .A1(n438), .A2(cfg_in_height_q[8]), .A3(n401), .A4(
        curr_y[7]), .A5(n400), .Y(n403) );
  OR2X1_RVT U738 ( .A1(n403), .A2(n402), .Y(n404) );
  AND2X1_RVT U739 ( .A1(n405), .A2(n404), .Y(n412) );
  NAND3X0_RVT U740 ( .A1(n407), .A2(eff_in_height[9]), .A3(n406), .Y(n411) );
  AO221X1_RVT U741 ( .A1(curr_y[7]), .A2(n409), .A3(curr_y[7]), .A4(n438), 
        .A5(n408), .Y(n410) );
  NAND4X0_RVT U742 ( .A1(n421), .A2(n412), .A3(n411), .A4(n410), .Y(n413) );
  NOR4X1_RVT U743 ( .A1(n416), .A2(n415), .A3(n414), .A4(n413), .Y(n418) );
  NOR3X0_RVT U744 ( .A1(in_eof), .A2(n418), .A3(n417), .Y(n475) );
  INVX0_RVT U745 ( .A(n421), .Y(n447) );
  AO22X1_RVT U746 ( .A1(n421), .A2(n419), .A3(n447), .A4(curr_y[0]), .Y(n420)
         );
  AO22X1_RVT U747 ( .A1(y_q[0]), .A2(n476), .A3(n475), .A4(n420), .Y(n117) );
  NAND3X0_RVT U748 ( .A1(n421), .A2(curr_y[1]), .A3(curr_y[0]), .Y(n424) );
  OA221X1_RVT U749 ( .A1(curr_y[1]), .A2(n421), .A3(curr_y[1]), .A4(curr_y[0]), 
        .A5(n424), .Y(n422) );
  AO22X1_RVT U750 ( .A1(y_q[1]), .A2(n476), .A3(n475), .A4(n422), .Y(n116) );
  INVX0_RVT U751 ( .A(n424), .Y(n426) );
  AO22X1_RVT U752 ( .A1(curr_y[2]), .A2(n424), .A3(n423), .A4(n426), .Y(n425)
         );
  AO22X1_RVT U753 ( .A1(y_q[2]), .A2(n476), .A3(n475), .A4(n425), .Y(n115) );
  NAND3X0_RVT U754 ( .A1(curr_y[2]), .A2(curr_y[3]), .A3(n426), .Y(n429) );
  OA221X1_RVT U755 ( .A1(curr_y[3]), .A2(curr_y[2]), .A3(curr_y[3]), .A4(n426), 
        .A5(n429), .Y(n427) );
  AO22X1_RVT U756 ( .A1(y_q[3]), .A2(n476), .A3(n475), .A4(n427), .Y(n114) );
  INVX0_RVT U757 ( .A(n429), .Y(n431) );
  AO22X1_RVT U758 ( .A1(curr_y[4]), .A2(n429), .A3(n428), .A4(n431), .Y(n430)
         );
  AO22X1_RVT U759 ( .A1(y_q[4]), .A2(n476), .A3(n475), .A4(n430), .Y(n113) );
  NAND3X0_RVT U760 ( .A1(curr_y[5]), .A2(curr_y[4]), .A3(n431), .Y(n434) );
  OA221X1_RVT U761 ( .A1(curr_y[5]), .A2(curr_y[4]), .A3(curr_y[5]), .A4(n431), 
        .A5(n434), .Y(n432) );
  AO22X1_RVT U762 ( .A1(y_q[5]), .A2(n476), .A3(n475), .A4(n432), .Y(n112) );
  INVX0_RVT U763 ( .A(n434), .Y(n436) );
  AO22X1_RVT U764 ( .A1(curr_y[6]), .A2(n434), .A3(n433), .A4(n436), .Y(n435)
         );
  AO22X1_RVT U765 ( .A1(y_q[6]), .A2(n476), .A3(n475), .A4(n435), .Y(n111) );
  NAND3X0_RVT U766 ( .A1(curr_y[7]), .A2(curr_y[6]), .A3(n436), .Y(n439) );
  OA221X1_RVT U767 ( .A1(curr_y[7]), .A2(curr_y[6]), .A3(curr_y[7]), .A4(n436), 
        .A5(n439), .Y(n437) );
  AO22X1_RVT U768 ( .A1(y_q[7]), .A2(n476), .A3(n475), .A4(n437), .Y(n110) );
  INVX0_RVT U769 ( .A(n439), .Y(n441) );
  AO22X1_RVT U770 ( .A1(curr_y[8]), .A2(n439), .A3(n438), .A4(n441), .Y(n440)
         );
  AO22X1_RVT U771 ( .A1(y_q[8]), .A2(n476), .A3(n475), .A4(n440), .Y(n109) );
  NAND3X0_RVT U772 ( .A1(curr_y[8]), .A2(curr_y[9]), .A3(n441), .Y(n445) );
  OA221X1_RVT U773 ( .A1(curr_y[9]), .A2(curr_y[8]), .A3(curr_y[9]), .A4(n441), 
        .A5(n445), .Y(n442) );
  AO22X1_RVT U774 ( .A1(y_q[9]), .A2(n476), .A3(n475), .A4(n442), .Y(n108) );
  INVX0_RVT U775 ( .A(n445), .Y(n443) );
  AO22X1_RVT U776 ( .A1(curr_y[10]), .A2(n445), .A3(n444), .A4(n443), .Y(n446)
         );
  AO22X1_RVT U777 ( .A1(y_q[10]), .A2(n476), .A3(n475), .A4(n446), .Y(n107) );
  AND2X1_RVT U778 ( .A1(n475), .A2(n447), .Y(n474) );
  AO22X1_RVT U779 ( .A1(x_q[0]), .A2(n476), .A3(n474), .A4(n448), .Y(n106) );
  AO22X1_RVT U780 ( .A1(curr_x[0]), .A2(n449), .A3(n448), .A4(curr_x[1]), .Y(
        n450) );
  AO22X1_RVT U781 ( .A1(x_q[1]), .A2(n476), .A3(n474), .A4(n450), .Y(n105) );
  NAND3X0_RVT U782 ( .A1(curr_x[0]), .A2(curr_x[2]), .A3(curr_x[1]), .Y(n453)
         );
  OA221X1_RVT U783 ( .A1(curr_x[2]), .A2(curr_x[0]), .A3(curr_x[2]), .A4(
        curr_x[1]), .A5(n453), .Y(n451) );
  AO22X1_RVT U784 ( .A1(x_q[2]), .A2(n476), .A3(n474), .A4(n451), .Y(n104) );
  INVX0_RVT U785 ( .A(n453), .Y(n455) );
  AO22X1_RVT U786 ( .A1(curr_x[3]), .A2(n453), .A3(n452), .A4(n455), .Y(n454)
         );
  AO22X1_RVT U787 ( .A1(x_q[3]), .A2(n476), .A3(n474), .A4(n454), .Y(n103) );
  NAND3X0_RVT U788 ( .A1(curr_x[3]), .A2(curr_x[4]), .A3(n455), .Y(n458) );
  OA221X1_RVT U789 ( .A1(curr_x[4]), .A2(curr_x[3]), .A3(curr_x[4]), .A4(n455), 
        .A5(n458), .Y(n456) );
  AO22X1_RVT U790 ( .A1(x_q[4]), .A2(n476), .A3(n474), .A4(n456), .Y(n102) );
  INVX0_RVT U791 ( .A(n458), .Y(n460) );
  AO22X1_RVT U792 ( .A1(curr_x[5]), .A2(n458), .A3(n457), .A4(n460), .Y(n459)
         );
  AO22X1_RVT U793 ( .A1(x_q[5]), .A2(n476), .A3(n474), .A4(n459), .Y(n101) );
  NAND3X0_RVT U794 ( .A1(curr_x[6]), .A2(curr_x[5]), .A3(n460), .Y(n463) );
  OA221X1_RVT U795 ( .A1(curr_x[6]), .A2(curr_x[5]), .A3(curr_x[6]), .A4(n460), 
        .A5(n463), .Y(n461) );
  AO22X1_RVT U796 ( .A1(x_q[6]), .A2(n476), .A3(n474), .A4(n461), .Y(n100) );
  INVX0_RVT U797 ( .A(n463), .Y(n465) );
  AO22X1_RVT U798 ( .A1(curr_x[7]), .A2(n463), .A3(n462), .A4(n465), .Y(n464)
         );
  AO22X1_RVT U799 ( .A1(x_q[7]), .A2(n476), .A3(n474), .A4(n464), .Y(n99) );
  NAND3X0_RVT U800 ( .A1(curr_x[8]), .A2(curr_x[7]), .A3(n465), .Y(n468) );
  OA221X1_RVT U801 ( .A1(curr_x[8]), .A2(curr_x[7]), .A3(curr_x[8]), .A4(n465), 
        .A5(n468), .Y(n466) );
  AO22X1_RVT U802 ( .A1(x_q[8]), .A2(n476), .A3(n474), .A4(n466), .Y(n98) );
  INVX0_RVT U803 ( .A(n468), .Y(n470) );
  AO22X1_RVT U804 ( .A1(curr_x[9]), .A2(n468), .A3(n467), .A4(n470), .Y(n469)
         );
  AO22X1_RVT U805 ( .A1(x_q[9]), .A2(n476), .A3(n474), .A4(n469), .Y(n97) );
  NAND2X0_RVT U806 ( .A1(curr_x[9]), .A2(n470), .Y(n471) );
  HADDX1_RVT U807 ( .A0(n472), .B0(n471), .SO(n473) );
  AO22X1_RVT U808 ( .A1(x_q[10]), .A2(n476), .A3(n474), .A4(n473), .Y(n96) );
  AO21X1_RVT U809 ( .A1(frame_active_q), .A2(n476), .A3(n475), .Y(n95) );
endmodule

