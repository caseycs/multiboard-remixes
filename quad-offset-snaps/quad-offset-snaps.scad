// 6.25 mm - Quad Offset Snaps (DS Part A) - Part 1 / Part 2, remix
// Remix of a Multiboard design by Keep Making (https://thangs.com/designer/Keep%20Making),
// under the Multiboard Licence: personal, non-commercial use only. See LICENSE.
// In the original STLs' coordinates.
// X: snap depth; Y: the two snaps; Z: 16 mm high.
// Part 2 is Part 1 turned 180 deg about Z, with a grooved (not bossed) inner
// corner and its bridge one bridge-thickness further up, countersunk.

part = 1; // [1, 2]

$fn = 128;

eps = 0.01;

snap_c   = 12.5 * sqrt(2);  // snap centres at y = +-snap_c
base_t   = 6.25;            // octagon base thickness
height   = 11.85;           // back face to snap tips
half_h   = 8;               // |z| <= 8
oct_a    = 12;              // base octagon apothem

// snap profile above the base: x offsets from the back face, apothem of the
// y-flats; the diagonals stop at snap_d
snap_x   = [base_t, 8.22049, 10.2, 11.67111, height];
snap_f   = [11.5603, 10.57506, 10.57506, 11.31061, 11.31061];
snap_d   = 10.57506;

// bridge between the snaps
bridge_w = snap_c - oct_a;        // half-width in y, 5.67767
bridge_h = oct_a * (sqrt(2) - 1); // half-height in z, 4.97056

// screw holes
hole_r   = 2.25;
csk_x0   = 0.25;                  // snap countersink: r hole_r -> csk_r1
csk_x1   = 2.75;                  //   (csk_x1 is also the snap cavity floor)
csk_r1   = 4.75;

// snap cavity
cav_x1   = 4.55;                  // end of the 45 deg lead-in
cav_a0   = 4.95;                  // octagon apothem at the floor (csk_x1)
cav_a1   = 6.75;                  // octagon apothem from cav_x1 on

// thread groove (single start, right hand about +X)
th_pitch = 3.125;
th_r_out = 7.15;
th_root  = 0.625;                 // axial width at th_r_out
th_flank = 0.41667;               // axial run per 0.4 mm radial
th_x0    = 5.44375;               // groove centre at angle 0 (+Y side of the snap)

// slot through Z: narrow half (z > 0 on the +Y snap) and wide half
slot_w   = [4.0, 4.5];            // half-widths
notch_x  = 7.65;
notch_r  = 2.5;
notch_in = 2.1;                   // notch centre inset from the wall
slot_rr  = 0.5;                   // rounded inner corners
mouth_l  = 0.4;                   // mouth chamfer: 0.2 wider over the last 0.4
mouth_w  = 0.2;
top_ch   = 0.5;                   // chamfer on the narrow half's z face

// alignment pocket on the cavity floor, wide half
pocket_z = 6.5;
pocket_s = [2, 1.6];
pocket_d = 0.2;

// round boss (part 1) / groove (part 2) along the inner octagon diagonals
boss_x   = 5.125;
boss_r   = 2.375;
boss_off = [-1.1, 2.1];           // axis offset from the diagonal, + = outside

x_back   = part == 1 ? -4.675653 : -4.701286;

// 2D (u, v) -> world (y, z), extrusion height -> world x
module to_x() multmatrix([[0, 0, 1, 0], [1, 0, 0, 0], [0, 1, 0, 0]]) children();

module x_slab(x0, x1) translate([x0, 0, 0]) to_x() linear_extrude(x1 - x0) children();

// octagon section: |y| <= f, |y| + |z| <= d*sqrt2, |z| <= h
module oct2d(f, d = undef, h = half_h) {
    intersection() {
        square([2 * f, 2 * h], center = true);
        rotate(45) square(2 * (d == undef ? f : d), center = true);
    }
}

// loft between two convex sections: children(0) at x0, children(1) at x1
module loft(x0, x1) hull() {
    x_slab(x0, x0 + 1e-3) children(0);
    x_slab(x1 - 1e-3, x1) children(1);
}

// everything below is in x offsets from the back face, snap centred at y = 0
module snap_outer() {
    x_slab(0, base_t) oct2d(oct_a);
    for (i = [0 : len(snap_x) - 2])
        loft(snap_x[i], snap_x[i + 1]) {
            oct2d(snap_f[i], i == 0 ? snap_f[i] : snap_d);
            oct2d(snap_f[i + 1], i == 0 ? snap_f[i + 1] : snap_d);
        }
}

// cylinders lying along the two inner diagonals (next to the bridge)
module corner_cylinders(off) {
    z0 = bridge_h + off * sqrt(2);
    for (s = [-1, 1])
        translate([boss_x, -oct_a, s * z0]) rotate([s * 45, 0, 0]) rotate([-90, 0, 0])
            cylinder(r = boss_r, h = 30, center = true);
}

module bosses() intersection() {
    corner_cylinders(boss_off[0]);
    translate([0, -oct_a, -half_h]) cube([base_t, 2 * oct_a, 2 * half_h]);
}

module helix_groove(x_from, x_to) {
    n = 120;                      // segments per turn
    r_in = 6.4;
    hw_out = th_root / 2;
    hw_in = hw_out + th_flank * (th_r_out - r_in) / 0.4;
    turns0 = floor((x_from - th_x0) / th_pitch) - 1;
    turns1 = ceil((x_to - th_x0) / th_pitch) + 1;
    steps = (turns1 - turns0) * n;
    prof = [[r_in, -hw_in], [th_r_out, -hw_out], [th_r_out, hw_out], [r_in, hw_in]];
    pts = [for (i = [0 : steps]) let(a = 360 * i / n, t = th_x0 + th_pitch * (turns0 + i / n))
              for (p = prof) [p[0] * cos(a), p[0] * sin(a), t + p[1]]];
    faces = concat(
        [[3, 2, 1, 0]],
        [for (i = [0 : steps - 1]) for (j = [0 : 3])
            let(a = 4 * i + j, b = 4 * i + (j + 1) % 4) [b, b + 4, a + 4, a]],
        [[4 * steps, 4 * steps + 1, 4 * steps + 2, 4 * steps + 3]]);
    intersection() {
        to_x() polyhedron(pts, faces);
        translate([x_from, -10, -10]) cube([x_to - x_from, 20, 20]);
    }
}

// slot section in the XY plane
module slot2d(w) {
    xe = height + 0.5;
    flare = mouth_w * (xe - height + mouth_l) / mouth_l;
    union() {
        hull() {
            for (s = [-1, 1]) translate([csk_x1 + slot_rr, s * (w - slot_rr)]) circle(slot_rr);
            translate([height - mouth_l, -w]) square([eps, 2 * w]);
        }
        polygon([[height - mouth_l, -w], [xe, -w - flare], [xe, w + flare], [height - mouth_l, w]]);
        for (s = [-1, 1]) translate([notch_x, s * (w - notch_in)]) circle(notch_r);
    }
}

module snap_cavity() {
    // screw hole with countersink
    rotate([0, 90, 0]) {
        translate([0, 0, -1]) cylinder(r = hole_r, h = csk_x0 + 1);
        translate([0, 0, csk_x0]) cylinder(r1 = hole_r, r2 = csk_r1, h = csk_x1 - csk_x0 + eps);
    }
    // 45 deg octagonal lead-in, then the octagon bore
    loft(csk_x1, cav_x1) { oct2d(cav_a0, h = 20); oct2d(cav_a1, h = 20); }
    x_slab(cav_x1 - eps, height + 1) oct2d(cav_a1, h = 20);
    helix_groove(cav_x1, height + 1);
    // narrow half: z from 0 up, chamfered along the side walls at the z face
    translate([0, 0, -eps]) linear_extrude(half_h + 1) slot2d(slot_w[0]);
    intersection() {
        minkowski() {
            translate([0, 0, half_h - top_ch]) linear_extrude(1e-3) slot2d(slot_w[0]);
            cylinder(r1 = 0, r2 = top_ch + 0.2, h = top_ch + 0.2, $fn = 32);
        }
        translate([csk_x1 + slot_rr, -10, 0]) cube([20, 20, 20]);
    }
    // wide half: z from 0 down
    translate([0, 0, -half_h - 1]) linear_extrude(half_h + 1 + eps) slot2d(slot_w[1]);
    // pocket on the floor of the wide half
    translate([0, 0, -pocket_z])
        loft(csk_x1 - pocket_d, csk_x1 + eps) {
            square(pocket_s[1], center = true);
            square(pocket_s[0], center = true);
        }
    if (part == 2) difference() {   // the groove leaves the y flat alone
        corner_cylinders(boss_off[1]);
        translate([-1, -oct_a - 1, -bridge_h]) cube([20, 4, 2 * bridge_h]);
    }
}

module snap() {
    translate([0, snap_c, 0]) difference() {
        union() {
            snap_outer();
            if (part == 1) bosses();
        }
        snap_cavity();
    }
}

// 3.125 mm thick; part 2's sits on part 1's
module bridge() {
    x0 = part == 1 ? 0 : 3.125;
    difference() {
        translate([x0, -bridge_w - 1, -bridge_h]) cube([3.125, 2 * (bridge_w + 1), 2 * bridge_h]);
        rotate([0, 90, 0]) {
            translate([0, 0, x0 - 1]) cylinder(r = hole_r, h = 3.125 + 2);
            if (part == 2)   // 45 deg countersink, as on the snaps
                translate([0, 0, x0 + 3.125 - 2.5])
                    cylinder(r1 = hole_r, r2 = csk_r1 + eps, h = 2.5 + eps);
        }
    }
}

module quad_offset_snaps() {
    translate([x_back, 0, 0]) {
        snap();
        rotate([180, 0, 0]) snap();
        bridge();
    }
}

rotate([0, 0, part == 1 ? 0 : 180]) quad_offset_snaps();
