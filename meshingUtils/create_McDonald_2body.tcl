ic_unload_tetin
# v0.2.0
#==============Parameters
# Meta
set {mesh_option} 2
# 0 = Geometry Creation Only
# 1 = DiffuserBody
# 2 = PlenumMesh

###TODO 
# Make the outer plenum wall edges have geometric distribution






#                                                   c4
#                                       p6*-------------------------*p7
#                                         |                         |
#                                       c3|                         |
#                                         |                         |
#                                       p5*                         |
#                                        /|                         |
#                                     c2/ |                         |
#                                 p3*  /  |                         |
#                        c1           /   |                         |
#               p1*-----------------*/    |                         |
#                 |                 ^p2,  |c7                       |c5
#                 |                  p4,  |                         |
#               c0|                  c6   |                         |
#                 |                       |                         |
#                 |                       |                         |
# rot_axis-->   p0*-----------------------*-------------------------*p8
#                                         ^p9

#### Geometry
set {in_len_multi}  3
    # multiplies by inlet diameter for diffuser/domain inlet length
set {out_len_multi} 6 
    # multiplies by inlet diameter for diffuser outlet length
set {in_r} 25.4
    # radius of diffuser/domain inlet
set {out_r} 28.9604
    # radius of diffuser outlet
set {dif_ang} 4.0 
    # HALF-ANGLE of the diffuser
set {trans_r} 20
    # radius of the transition fillet
set {out_expan_r_multi} 5
    # multiplies by inlet diameter

#### Meshing 
## Control Circle parameters
set {ccirc_inletr} 12
    # radius @ inlet face
set {ccirc_outletinner} 20
    # inner circle radius @ domain outlet
set {ccirc_outletouter} 45
    # outer circle radius @ domain outlet

## Sweep parameters
set {ogrid_inlet_sweepn} 100
    # number of sweeps for the domain inlet
set {ogrid_diff_sweepn} 30
    # number of sweeps for the diffuser
set {ogrid_plenum_sweepn} 150
    # number of sweeps for the plenum

## FOR O-GRID MESHING
set {ogrid_center_elementn} 21
    # number of elements to put on one side of center octogon

set {ogrid_diffring_layern} 50
    # number of layers in diffuser ring
set {ogrid_diffring_initheight} 0.0025
    # value of initial height layer in mm
set {ogrid_diffring_expansionrate} 1.2
    # expotential expansion rate of diffuser ring layers

set {ogrid_pleninner_layern} 40
    # number of layers in inner plenum ring
set {ogrid_pleninner_initheight} 0.065
    # value of initial height layer in mm
set {ogrid_pleninner_expansionrate} 1.2
    # expotential expansion rate of inner plenum ring layers

set {ogrid_plenouter_layern} 34
    # number of layers in outer plenum ring
set {ogrid_plenouter_initheight} .065
    # value of initial height layer in mm
set {ogrid_plenouter_expansionrate} 1.5
    # expotential expansion rate of inner plenum ring layers


##FOR TET & O-GRID MESH
set {global_ref} 2
    # global reference size (not used as reference in this script)
set {global_max_abs} 4
    # absolute global size
set {walls_max_abs} 2
    # absolute maximum element size on wall
set {vol_expanratio} 1.1
    # expansion rate for volume element mesh

###################################
######## Calculation of Parameters
###################################

# Setting basic diffuser dimensions
set {in_len} [expr $in_len_multi * $in_r * 2]
set {out_len} [expr $out_len_multi * $in_r * 2]
set {out_expan_r} [expr $out_expan_r_multi * $in_r]


# Setting control circle parameters
set {ccirc_diffinr} $ccirc_inletr
    # radius @ diffuser inlet face, same radius @ domain inlet face
set {ccirc_diffoutr} [expr $ccirc_diffinr * ($out_r / $in_r)]
    # radius @ diffuser outlet, expands with area expansion


# Setting the diffuser geometry point values
set {dif_angrad} [expr $dif_ang*(3.141592653589793/180)]
set {05_i} [expr ($out_r - $in_r - $trans_r * (1 - cos($dif_angrad))) / tan($dif_angrad) + $trans_r * sin($dif_angrad) + $in_len]
set {05_j} $out_r
# set {05_j} [expr $in_r + $dif_len * tan($dif_angrad)]
set {07_i} [expr $05_i + $out_len]
set {07_j} $out_expan_r
ic_geo_set_units mm
###
ic_geo_new_family GEOM
ic_boco_set_part_color GEOM
ic_empty_tetin
ic_point {} GEOM pnt.00 0,0,0
ic_point {} GEOM pnt.01 0,$in_r,0
ic_point {} GEOM pnt.02 0,$in_r,$in_len
ic_point {} GEOM pnt.03 0,[expr $in_r + $trans_r],$in_len
ic_point {} GEOM pnt.05 0,$05_j,$05_i
# make arc curve and associated point
ic_curve arc_ctr_rad GEOM crv.06 "pnt.03 pnt.02 pnt.05 $trans_r 0 $dif_ang"
ic_point curve_end GEOM pnt.04 {crv.06 ymax}
ic_point {} GEOM pnt.06 0,$out_expan_r,$05_i
ic_point {} GEOM pnt.07 0,$07_j,$07_i
ic_point {} GEOM pnt.08 0,0,$07_i
ic_point {} GEOM pnt.09 0,0,$05_i
# making Curves
ic_curve point GEOM crv.00 {pnt.00 pnt.01}
ic_curve point GEOM crv.01 {pnt.01 pnt.02}
ic_curve point GEOM crv.02 {pnt.04 pnt.05}
ic_curve point GEOM crv.03 {pnt.05 pnt.06}
ic_curve point GEOM crv.04 {pnt.06 pnt.07}
ic_curve point GEOM crv.05 {pnt.07 pnt.08}
ic_curve point GEOM crv.06 {pnt.05 pnt.09}
# make revolved surfaces
ic_geo_cre_srf_rev GEOM srf.00 {crv.00 crv.01 crv.06 crv.02 crv.07} pnt.00 {0 0 1} 0 360 c 1
ic_geo_cre_srf_rev GEOM srf.00 {crv.07 crv.03 crv.04 crv.05} pnt.08 {0 0 1} 0 360 c 1
ic_geo_new_family DIFFUSER
ic_boco_set_part_color DIFFUSER
ic_geo_create_body {srf.00 srf.00.1 srf.00.2 srf.00.3 srf.01} {} DIFFUSER
ic_geo_new_family PLENUM
ic_boco_set_part_color PLENUM
ic_geo_create_body {srf.00.5 srf.00.6 srf.00.7 srf.00.8} {} PLENUM


#Creating parts for the surfaces
ic_geo_set_part surface srf.00 INLET 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.1 srf.00.2 srf.00.3} WALLS 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.8} OUTLETMAIN 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.7} OUTLETWALLS 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.6} NONSLIPWALL 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.5} INTERFACEDIFF 0
ic_delete_empty_parts 

# Setting Family meshing parameters
ic_geo_set_family_params WALLS prism 1 emax $walls_max_abs

##############################
#### Creating control circles
##############################

#creating Perpendicular circle points
ic_point projcurv GEOM pnt.11 {GEOM.19 srf.00.1e14}
ic_point projcurv GEOM pnt.12 {GEOM.19 srf.00.1e12}
ic_point projcurv GEOM pnt.13 {GEOM.19 srf.00.3e20}
ic_point projcurv GEOM pnt.14 {GEOM.19 srf.00.7e34}

#create center point for transition circle
ic_point {} GEOM pnt.15 0,0,$in_len


## Creating Control Circles
ic_curve arc_ctr_rad GEOM crv.11 "GEOM.19 GEOM.21 pnt.11 $ccirc_inletr 0 360"
ic_curve arc_ctr_rad GEOM crv.12 "pnt.15 GEOM.25 pnt.12 $ccirc_diffinr 0 360"
ic_curve arc_ctr_rad GEOM crv.13 "GEOM.45 GEOM.33 pnt.13 $ccirc_diffoutr 0 360"
ic_curve arc_ctr_rad GEOM crv.13 "GEOM.57 GEOM.54 pnt.14 $ccirc_outletouter 0 360"
ic_curve arc_ctr_rad GEOM crv.13 "GEOM.57 GEOM.54 pnt.14 $ccirc_outletinner 0 360"


### DIFFUSER=OctOgrid PLENUM=OctOgrid
##
###### NOT VALIDATED!!!!!!!
##
if {$mesh_option == 1} {
    ######### DIFFUSER BODY
    puts "Starting OGrid for Diffuser Body"
    # Make Initial Block
    ic_hex_initialize_blocking {surface srf.00 surface srf.00.1 surface srf.00.2 surface srf.00.3} DIFFUSER 0 101
    ic_hex_unblank_blocks 
    ic_hex_multi_grid_level 0
    ic_hex_projection_limit 0
    ic_hex_default_bunching_law default 2
    ic_hex_floating_grid off
    ic_hex_transfinite_degree 1
    ic_hex_unstruct_face_type several_tris
    ic_hex_set_unstruct_face_method uniform_quad
    ic_hex_set_n_tetra_smoothing_steps 20
    ic_hex_error_messages off_minor

    # Split at Throat
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 25 26 curve:srf.00.1e12:0.1253280303717014 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN
    ic_hex_undo_major_end split_grid

    # Split down the middle
    ic_hex_split_grid 25 41 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN
    ic_hex_split_grid 21 25 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN

    # # Associate Edges with Curves
    ic_hex_set_edge_projection 86 41 0 1 srf.00.1e14
    ic_hex_set_edge_projection 108 41 0 1 srf.00.1e14
    ic_hex_set_edge_projection 37 108 0 1 srf.00.1e14
    ic_hex_set_edge_projection 85 37 0 1 srf.00.1e14
    ic_hex_set_edge_projection 21 85 0 1 srf.00.1e14
    ic_hex_set_edge_projection 21 106 0 1 srf.00.1e14
    ic_hex_set_edge_projection 106 25 0 1 srf.00.1e14
    ic_hex_set_edge_projection 25 86 0 1 srf.00.1e14
    # ic_hex_find_comp_curve srf.00.1e12
    ic_hex_set_edge_projection 90 74 0 1 srf.00.1e12
    ic_hex_set_edge_projection 113 74 0 1 srf.00.1e12
    ic_hex_set_edge_projection 70 113 0 1 srf.00.1e12
    ic_hex_set_edge_projection 89 70 0 1 srf.00.1e12
    ic_hex_set_edge_projection 69 89 0 1 srf.00.1e12
    ic_hex_set_edge_projection 69 111 0 1 srf.00.1e12
    ic_hex_set_edge_projection 111 73 0 1 srf.00.1e12
    ic_hex_set_edge_projection 73 90 0 1 srf.00.1e12
    # ic_hex_find_comp_curve srf.00.3e20
    ic_hex_set_edge_projection 94 42 0 1 srf.00.3e20
    ic_hex_set_edge_projection 118 42 0 1 srf.00.3e20
    ic_hex_set_edge_projection 38 118 0 1 srf.00.3e20
    ic_hex_set_edge_projection 93 38 0 1 srf.00.3e20
    ic_hex_set_edge_projection 22 93 0 1 srf.00.3e20
    ic_hex_set_edge_projection 22 116 0 1 srf.00.3e20
    ic_hex_set_edge_projection 116 26 0 1 srf.00.3e20
    ic_hex_set_edge_projection 26 94 0 1 srf.00.3e20

    # Snap Edges to Associated Curves
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # Add Blocks and faces to be used in O-Grid
    ic_hex_mark_blocks superblock 28
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 31
    ic_hex_mark_blocks superblock 30
    ic_hex_mark_blocks superblock 32
    ic_hex_mark_blocks superblock 33
    ic_hex_mark_blocks superblock 27
    ic_hex_mark_blocks superblock 29

    ic_hex_mark_blocks face_neighbors corners { 25 86 106 107 } { 41 86 108 107 } { 37 85 108 107 } { 21 85 106 107 } { 26 94 116 117 } { 42 94 118 117 } { 38 93 118 117 } { 22 93 116 117 }

    # Create O Grid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN -version 50

    # Associate vertices with control circles
    ic_hex_set_node_projection 146 crv.11
    ic_hex_set_node_projection 161 crv.11
    ic_hex_set_node_projection 156 crv.11
    ic_hex_set_node_projection 151 crv.11
    ic_hex_set_node_projection 141 crv.11
    ic_hex_set_node_projection 126 crv.11
    ic_hex_set_node_projection 131 crv.11
    ic_hex_set_node_projection 136 crv.11

    ic_hex_set_node_projection 147 crv.12
    ic_hex_set_node_projection 162 crv.12
    ic_hex_set_node_projection 157 crv.12
    ic_hex_set_node_projection 152 crv.12
    ic_hex_set_node_projection 142 crv.12
    ic_hex_set_node_projection 127 crv.12
    ic_hex_set_node_projection 132 crv.12
    ic_hex_set_node_projection 137 crv.12

    ic_hex_set_node_projection 148 crv.13
    ic_hex_set_node_projection 163 crv.13
    ic_hex_set_node_projection 158 crv.13
    ic_hex_set_node_projection 153 crv.13
    ic_hex_set_node_projection 143 crv.13
    ic_hex_set_node_projection 128 crv.13
    ic_hex_set_node_projection 133 crv.13
    ic_hex_set_node_projection 138 crv.13

    # Snap vertices to control circles
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 151 n $ogrid_diffring_layern h1 $ogrid_diffring_initheight h2rel 0.0 r1 $ogrid_diffring_expansionrate r2 2 lmax 0 exp1 copy_to_parallel unlocked

    # Set center block element spacing
    ic_hex_set_mesh 107 131 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 107 141 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 107 146 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 156 107 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

    # Set number of sweeps
    ic_hex_set_mesh 21 69 n $ogrid_inlet_sweepn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 22 69 n $ogrid_diff_sweepn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

}

if {$mesh_option == 2} {
    #######
    # PLENUM BODY
    #######

    # Make Initial Block
    ic_hex_initialize_blocking {surface srf.00.6 surface srf.00.7 surface srf.00.8 surface srf.00.5} DIFFUSER 0 101
    ic_hex_unblank_blocks 
    ic_hex_multi_grid_level 0
    ic_hex_projection_limit 0
    ic_hex_default_bunching_law default 2
    ic_hex_floating_grid off
    ic_hex_transfinite_degree 1
    ic_hex_unstruct_face_type several_tris
    ic_hex_set_unstruct_face_method uniform_quad
    ic_hex_set_n_tetra_smoothing_steps 20
    ic_hex_error_messages off_minor

    # Split Down Middle
    ic_hex_split_grid 21 25 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN
    ic_hex_split_grid 25 41 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN

    # Associate Edges to Curves
    ic_hex_set_edge_projection 88 41 0 1 srf.00.6e30
    ic_hex_set_edge_projection 70 41 0 1 srf.00.6e30
    ic_hex_set_edge_projection 86 37 0 1 srf.00.6e30
    ic_hex_set_edge_projection 37 70 0 1 srf.00.6e30
    ic_hex_set_edge_projection 21 86 0 1 srf.00.6e30
    ic_hex_set_edge_projection 21 69 0 1 srf.00.6e30
    ic_hex_set_edge_projection 69 25 0 1 srf.00.6e30
    ic_hex_set_edge_projection 25 88 0 1 srf.00.6e30
    ic_hex_set_edge_projection 93 42 0 1 srf.00.7e34
    ic_hex_set_edge_projection 74 42 0 1 srf.00.7e34
    ic_hex_set_edge_projection 38 74 0 1 srf.00.7e34
    ic_hex_set_edge_projection 91 38 0 1 srf.00.7e34
    ic_hex_set_edge_projection 22 91 0 1 srf.00.7e34
    ic_hex_set_edge_projection 22 73 0 1 srf.00.7e34
    ic_hex_set_edge_projection 26 93 0 1 srf.00.7e34
    ic_hex_set_edge_projection 73 26 0 1 srf.00.7e34

    # Snap Edges to Associated Curves
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # Select Blocks and Faces for Ogrid
    ic_hex_mark_blocks superblock 29
    ic_hex_mark_blocks superblock 27
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 28

    ic_hex_mark_blocks face_neighbors corners { 26 93 73 92 } { 42 93 74 92 } { 38 91 74 92 } { 22 91 73 92 } { 41 88 70 87 } { 37 86 70 87 } { 21 86 69 87 } { 25 88 69 87 }

    # Create Ogrid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN NONSLIPWALL INTERFACEDIFF -version 50

    # Split Ring blocks in half
    ic_hex_split_grid 38 122 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN NONSLIPWALL INTERFACEDIFF

    # Associate inner ring edges to diffuser outlet
    ic_hex_set_edge_projection 142 144 0 1 srf.00.3e20
    ic_hex_set_edge_projection 141 142 0 1 srf.00.3e20
    ic_hex_set_edge_projection 140 141 0 1 srf.00.3e20
    ic_hex_set_edge_projection 140 143 0 1 srf.00.3e20
    ic_hex_set_edge_projection 143 145 0 1 srf.00.3e20
    ic_hex_set_edge_projection 145 146 0 1 srf.00.3e20
    ic_hex_set_edge_projection 146 147 0 1 srf.00.3e20
    ic_hex_set_edge_projection 144 147 0 1 srf.00.3e20

    # Associate vertices to control circles
    ic_hex_set_node_projection 125 crv.13
    ic_hex_set_node_projection 121 crv.13
    ic_hex_set_node_projection 113 crv.13
    ic_hex_set_node_projection 101 crv.13
    ic_hex_set_node_projection 105 crv.13
    ic_hex_set_node_projection 109 crv.13
    ic_hex_set_node_projection 117 crv.13
    ic_hex_set_node_projection 129 crv.13

    ic_hex_set_node_projection 126 crv.15
    ic_hex_set_node_projection 122 crv.15
    ic_hex_set_node_projection 114 crv.15
    ic_hex_set_node_projection 102 crv.15
    ic_hex_set_node_projection 106 crv.15
    ic_hex_set_node_projection 110 crv.15
    ic_hex_set_node_projection 118 crv.15
    ic_hex_set_node_projection 130 crv.15
    
    ic_hex_set_node_projection 152 crv.14
    ic_hex_set_node_projection 150 crv.14
    ic_hex_set_node_projection 149 crv.14
    ic_hex_set_node_projection 148 crv.14
    ic_hex_set_node_projection 151 crv.14
    ic_hex_set_node_projection 153 crv.14
    ic_hex_set_node_projection 154 crv.14
    ic_hex_set_node_projection 155 crv.14

    # Snap associations to geometry
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # Define inner ring inflation layers
    ic_hex_set_mesh 141 113 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 140 101 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 143 105 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 145 109 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 146 117 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 147 129 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 144 125 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 142 121 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked

    # Define outer ring inflation layering
    ic_hex_set_mesh 69 143 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 25 145 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 88 146 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 41 147 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 70 144 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 37 142 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 86 141 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 21 140 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked

    #### NOTE: The edges on the outlet face of the plenum are assumed to make automatic linear distribution

    # Define Center block element numbering
    ic_hex_set_mesh 125 87 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 87 117 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 105 87 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 113 87 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

    # Set number of sweeps
    ic_hex_set_mesh 25 26 n $ogrid_inlet_sweepn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

}   