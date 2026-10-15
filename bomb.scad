// ============================================================================
// ACME-STYLE CARTOON BOMB -- "THREAT-O-METER" desk toy
// ----------------------------------------------------------------------------
// A family-friendly parody of the classic cartoon prop (and of a certain
// 2012 UN speech diagram): a round bomb with a fuse cap and a sliding
// red-line indicator that snaps along an engraved threat-level track.
//
// One file, four printable parts + previews:
//   part = "body"      sphere, flat base, fuse socket, face pocket
//   part = "cap"       fuse cap + fuse nub (seats in the top socket)
//   part = "track"     T-slot track plate with engraved markings
//   part = "slider"    snap-in red-line indicator with a flex-detent finger
//   part = "assembly"  all parts in place (preview / fit check)
//   part = "section"   cutaway of the assembly (debug / fit check)
//
// Export STLs (sphere centre is the design origin):
//   openscad -o stl/bomb_body.stl  -D 'part="body"'   bomb.scad
//   openscad -o stl/fuse_cap.stl   -D 'part="cap"'    bomb.scad
//   openscad -o stl/track.stl      -D 'part="track"'  bomb.scad
//   openscad -o stl/slider.stl     -D 'part="slider"' bomb.scad
// or run ./build_stls.sh
// ============================================================================

// ------------------------------- parameters --------------------------------

part = "assembly";            // body | cap | track | slider | assembly | section

bomb_radius = 45;             // sphere radius (mm)
base_flat   = 0.42;           // flat-base chord radius, fraction of bomb_radius

// fuse cap
cap_flange_r  = 15;           // flange radius
cap_flange_h  = 6;            // flange thickness
cap_dome_h    = 7;            // dome height above flange
socket_r      = 10;           // socket hole radius in the bomb top
socket_depth  = 12;           // socket depth
fuse_r        = 3.2;          // fuse nub radius
fuse_h        = 11;           // fuse nub height above dome
cap_clearance = 0.30;         // stem/socket clearance

// track plate (the "control panel" on the bomb face)
track_width  = 48;            // plate width  (x)
track_height = 64;            // plate height (z)
track_thick  = 8.4;           // plate depth  (y)
pocket_depth = 0.55;          // pocket floor, fraction of bomb_radius (0..1)
track_zc     = 0;             // track centre height on the bomb
niche_clear  = 0.40;          // clearance between plate and pocket

// T-slot channel: narrow neck at the face, wide cavity behind it
slot_open_w  = 8;             // slot opening width
slot_open_d  = 3;             // slot opening depth (from the face)
slot_inner_w = 16;            // cavity width
slot_inner_d = 3;             // cavity depth (behind the opening)
slider_len   = 12;            // indicator tongue length along the slide

// click-stops: the tongue's +x edge is a cantilevered spring finger
// (freed by a slit) whose bump snaps into divots on the cavity wall
detents       = true;
detent_bump_r = 0.80;         // bump radius on the spring finger
detent_div_r  = 0.75;         // divot radius in the cavity wall
slit_w        = 0.80;         // width of the slit freeing the finger
finger_w      = 1.30;         // finger thickness (x)
bump_off      = -4;           // bump height relative to the bar centre (z)

// engraved / embossed markings on the track face
markings      = "engrave";    // "engrave" | "emboss"
engrave_depth = 0.7;          // engrave depth (emboss stands ~0.8 proud)
font_name     = "Liberation Sans:style=Bold";
pct_size      = 3.8;
stage_size    = 3.2;
title_size    = 4.4;
title_text    = "THREAT-O-METER";

// marks are fractions of slider travel (0 bottom .. 1 top);
// stage captions sit centred in the band between consecutive marks
mark_pos     = [0, 0.25, 0.5, 0.75, 0.9, 1.0];
mark_labels  = ["0%", "25%", "50%", "75%", "90%", "100%"];
stage_labels = ["STAGE 1", "STAGE 2", "STAGE 3", "RED LINE", "FINAL"];

// red-line indicator bar
bar_len   = 30;               // bar length (x)
bar_h     = 3.5;              // bar height (z)
bar_th    = 2.4;              // bar thickness (y)
bar_gap   = 0.6;              // clearance between bar and track face
arrow_tip = true;             // little pointer on the right end

clearance = 0.30;             // general slider/track clearance
demo_pct  = 0.9;              // slider position in "assembly" (the joke: 90%)

$fn = 128;

// ---------------------------- derived geometry -----------------------------

flat_d   = bomb_radius * sqrt(1 - base_flat*base_flat); // centre -> base plane
pocket_y = bomb_radius * pocket_depth;                  // pocket floor
face_y   = pocket_y + track_thick;                      // track front face
bar_front_y = face_y + bar_gap + bar_th;                // slider front surface

cav_y0   = face_y - slot_open_d - slot_inner_d;         // cavity back wall
cav_y1   = face_y - slot_open_d;                        // cavity front wall
cav_x    = slot_inner_w/2;                              // cavity half width
neck_x   = slot_open_w/2;                               // opening half width
cav_ymid = (cav_y0 + cav_y1)/2;

// slider travel: indicator centre at the lowest / highest mark
end_margin = 10;
z_lo = track_zc - track_height/2 + end_margin;
z_hi = track_zc + track_height/2 - end_margin;
span = z_hi - z_lo;

// channel ends (plate-local z): open at plate bottom, closed near the top
ch_z0 = -track_height/2 - 0.5;
ch_z1 = z_hi - track_zc + slider_len/2 + 1.2;

// spring finger on the +x edge of the tongue (world coords on the slider)
finger_x0 = cav_x - clearance - finger_w;   // finger inner face (slit outer wall)
root_z    = slider_len/2 - 3;               // finger root: top 3 mm of tongue

function mz(i) = z_lo + span*mark_pos[i];                  // mark z (world)
function bz(i) = z_lo + span*(mark_pos[i]+mark_pos[i+1])/2; // band centre (world)
function dz(i) = mz(i) + bump_off;                         // divot z (world)
function lz(z) = z - track_zc;                             // world -> plate-local z

// ------------------------------ bomb body -----------------------------------

// sphere centred at the design origin; export lifts the flat base to z=0
module bomb_body_geo() {
  difference() {
    intersection() {
      sphere(r = bomb_radius);
      translate([-bomb_radius, -bomb_radius, -flat_d])
        cube([2*bomb_radius, 2*bomb_radius, flat_d + bomb_radius]);
    }
    // fuse-cap socket on top
    translate([0,0,bomb_radius - socket_depth])
      cylinder(r = socket_r, h = socket_depth + 1);
    // recessed face pocket for the track plate
    translate([0, (pocket_y + bomb_radius + 1)/2, track_zc])
      cube([track_width + 2*niche_clear,
            bomb_radius + 1 - pocket_y,
            track_height + 2*niche_clear], center = true);
  }
}

module bomb_body() translate([0,0,flat_d]) bomb_body_geo();

// ------------------------------- fuse cap -----------------------------------

// built in world coords (seated on the sphere centred at the origin)
module fuse_cap_geo() {
  union() {
    // stem into the socket (long enough to overlap the dished flange)
    translate([0,0,bomb_radius - socket_depth])
      cylinder(r = socket_r - cap_clearance, h = socket_depth + 4);
    difference() {
      union() {
        // flange: its base dips below the sphere surface so the
        // dished underside seats on the bomb top
        translate([0,0,bomb_radius - 3])
          cylinder(r = cap_flange_r, h = cap_flange_h);
        // squashed dome on the flange
        translate([0,0,bomb_radius - 3 + cap_flange_h])
          scale([1,1,cap_dome_h/cap_flange_r]) sphere(r = cap_flange_r);
        // fuse nub + rounded tip
        translate([0,0,bomb_radius - 3 + cap_flange_h + cap_dome_h*0.6])
          cylinder(r = fuse_r, h = fuse_h);
        translate([0,0,bomb_radius - 3 + cap_flange_h + cap_dome_h*0.6 + fuse_h])
          sphere(r = fuse_r * 1.25);
      }
      // dish the underside to the sphere (slightly proud = seat clearance)
      sphere(r = bomb_radius + 0.4);
    }
  }
}

// exported orientation: stem down, base at z=0
module fuse_cap() translate([0,0,-(bomb_radius - socket_depth)]) fuse_cap_geo();

// -------------------------- track plate + markings --------------------------

// text/tick helpers on the plate face, PLATE-LOCAL coords
// (plate centred at origin, face at y = +track_thick/2)
module face_text(str, x, z, size, halign = "left") {
  top = (markings == "engrave") ? track_thick/2 + 0.02
                                : track_thick/2 + 0.8;
  bot = (markings == "engrave") ? track_thick/2 - engrave_depth
                                : track_thick/2 - 0.05;
  translate([x, top, z]) rotate([90,0,0])
    linear_extrude(height = top - bot)
      mirror([1,0,0])          // un-mirror when read from +y (the face)
        text(str, size = size, font = font_name,
             halign = halign, valign = "center");
}

module face_tick(x0, x1, z, w = 1.5) {
  top = (markings == "engrave") ? track_thick/2 + 0.02
                                : track_thick/2 + 0.8;
  bot = (markings == "engrave") ? track_thick/2 - engrave_depth
                                : track_thick/2 - 0.05;
  translate([(x0+x1)/2, (top+bot)/2, z])
    cube([abs(x1-x0), top - bot, w], center = true);
}

module all_markings() {
  for (i = [0 : len(mark_pos)-1]) {
    // tick bars flanking the slot
    face_tick(neck_x + 0.7, neck_x + 6.5, lz(mz(i)));
    face_tick(-neck_x - 6.5, -neck_x - 0.7, lz(mz(i)));
    // % label, right side
    face_text(mark_labels[i], 17, lz(mz(i)), pct_size, "center");
  }
  // stage captions, left side, centred in each band
  for (i = [0 : len(stage_labels)-1])
    face_text(stage_labels[i], -16.5, lz(bz(i)), stage_size, "center");
  // title along the bottom of the panel
  face_text(title_text, 0, -track_height/2 + 4, title_size, "center");
}

// slotted track plate, plate-local coords
module track_geo() {
  difference() {
    union() {
      cube([track_width, track_thick, track_height], center = true);
      if (markings == "emboss") all_markings();
    }
    // T-slot channel: neck through the face + wide cavity behind, open bottom
    translate([0, track_thick/2 - slot_open_d/2 + 0.01, (ch_z0+ch_z1)/2])
      cube([slot_open_w, slot_open_d + 0.02, ch_z1 - ch_z0], center = true);
    translate([0, (cav_y0+cav_y1)/2 - pocket_y - track_thick/2, (ch_z0+ch_z1)/2])
      cube([slot_inner_w, slot_inner_d, ch_z1 - ch_z0], center = true);
    // detent divots on the +x cavity wall
    if (detents)
      for (i = [0 : len(mark_pos)-1])
        translate([cav_x + 0.05, cav_ymid - pocket_y - track_thick/2, lz(dz(i))])
          sphere(r = detent_div_r);
    if (markings == "engrave") all_markings();
  }
}

// track placed in the bomb pocket (assembly view)
module track_world() {
  translate([0, pocket_y + track_thick/2, track_zc]) track_geo();
}

// exported orientation: lying flat on the bed, engraved face up
module track() {
  translate([0,0,track_thick/2])
    rotate([90,0,0]) track_geo();
}

// ----------------------------- red-line slider ------------------------------

// built in world coords, indicator centre at z = sc
module slider_geo(sc) {
  fz0 = sc - slider_len/2;
  fz1 = sc + slider_len/2;
  difference() {
    union() {
      // wide flange riding in the cavity
      translate([0, (cav_y0 + clearance + cav_y1 - clearance)/2, sc])
        cube([slot_inner_w - 2*clearance,
              cav_y1 - cav_y0 - 2*clearance,
              slider_len], center = true);
      // neck through the slot opening out to the bar (overlaps both)
      translate([0, (cav_y1 - clearance - 0.1 + face_y + bar_gap + 0.1)/2, sc])
        cube([slot_open_w - 2*clearance,
              face_y + bar_gap + 0.1 - cav_y1 + clearance + 0.1,
              slider_len], center = true);
      // the red line bar across the face
      translate([0, bar_front_y, sc]) rotate([90,0,0])
        linear_extrude(height = bar_th)
          polygon(arrow_tip
            ? [[-bar_len/2,-bar_h/2],[bar_len/2-6,-bar_h/2],
               [bar_len/2+4,0],[bar_len/2-6,bar_h/2],[-bar_len/2,bar_h/2]]
            : [[-bar_len/2,-bar_h/2],[bar_len/2,-bar_h/2],
               [bar_len/2,bar_h/2],[-bar_len/2,bar_h/2]]);
      // detent bump on the finger (= tongue's +x edge below the root)
      if (detents)
        translate([cav_x - clearance, cav_ymid, sc + bump_off])
          sphere(r = detent_bump_r);
    }
    // slit freeing the finger: sever the +x edge of the flange
    // (the finger itself) from the tongue below the root so it
    // can flex in x. Only cuts the slit -- the finger stays.
    if (detents)
      translate([finger_x0 - slit_w/2,
                 (cav_y0 + clearance + cav_y1 - clearance)/2,
                 (fz0 - 0.2 + sc + root_z)/2])
        cube([slit_w,
              cav_y1 - cav_y0 - 2*clearance + 0.2,
              sc + root_z - fz0 + 0.2], center = true);
  }
}

// exported orientation: bar face down on the bed
module slider() {
  translate([0,0,bar_front_y])
    rotate([-90,0,0])
      translate([0,0,-(z_lo + span*demo_pct)])
        slider_geo(z_lo + span*demo_pct);
}

// ------------------------------ top level -----------------------------------

if (part == "body")   bomb_body();
if (part == "cap")    fuse_cap();
if (part == "track")  track();
if (part == "slider") slider();

module asm() {
  color("dimgray")  bomb_body_geo();
  color("gray")     fuse_cap_geo();
  color("#555555")  track_world();
  color("red")      slider_geo(z_lo + span*demo_pct);
}

if (part == "assembly") translate([0,0,flat_d]) asm();

if (part == "section")
  translate([0,0,flat_d]) intersection() {
    asm();
    translate([0,-100,-100]) cube([200,200,200]);    // keep the +x half
  }
