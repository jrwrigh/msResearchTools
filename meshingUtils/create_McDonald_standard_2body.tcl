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
set {in_len_multi}  1
    # multiplies by inlet diameter for diffuser/domain inlet length
set {out_len_multi} 5 
    # multiplies by inlet diameter for diffuser outlet length
set {in_r} 130
    # radius of diffuser/domain inlet
set {out_r} 219.08
    # radius of diffuser outlet
set {dif_ang} 10
    # HALF-ANGLE of the diffuser
set {trans_r} 10
    # radius of the transition fillet
set {out_expan_r_multi} 5
    # multiplies by inlet radius

#### Meshing 
## Control Circle parameters
set {ccirc_inletr} 100
    # radius @ inlet face
set {ccirc_outletinner} 110
    # inner circle radius @ domain outlet
set {ccirc_outletouter} 330
    # outer circle radius @ domain outlet

## Sweep parameters
set {ogrid_inlet_sweepn} 50
    # number of sweeps for the domain inlet
set {ogrid_diff_sweepn} 70
    # number of sweeps for the diffuser
set {ogrid_plenum_sweepn} 90
    # number of sweeps for the plenum
set {ogrid_plenum_sweepinit} 8
    # initial length of sweep mesh element
set {ogrid_plenum_sweepexpanratio} 1.5
    # geometric expansion ratio of the sweep

## FOR O-GRID MESHING
set {ogrid_center_elementn} 42
    # number of elements to put on one side of center octogon

set {ogrid_diffring_layern} 50
    # number of layers in diffuser ring
set {ogrid_diffring_initheight} 0.02
    # value of initial height layer in mm
set {ogrid_diffring_expansionrate} 1.2
    # expotential expansion rate of diffuser ring layers

set {ogrid_pleninner_layern} 40
    # number of layers in inner plenum ring
set {ogrid_pleninner_initheight} 0.15
    # value of initial height layer in mm
set {ogrid_pleninner_expansionrate} 1.2
    # expotential expansion rate of inner plenum ring layers

set {ogrid_plenouter_layern} 40
    # number of layers in outer plenum ring
set {ogrid_plenouter_initheight} .2
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


    # Associate Edges with Curves
    ic_hex_set_edge_projection 37 41 0 1 srf.00.1e14
    ic_hex_set_edge_projection 21 37 0 1 srf.00.1e14
    ic_hex_set_edge_projection 21 25 0 1 srf.00.1e14
    ic_hex_set_edge_projection 25 41 0 1 srf.00.1e14
    ic_hex_set_edge_projection 70 74 0 1 srf.00.1e12
    ic_hex_set_edge_projection 69 70 0 1 srf.00.1e12
    ic_hex_set_edge_projection 69 73 0 1 srf.00.1e12
    ic_hex_set_edge_projection 73 74 0 1 srf.00.1e12
    ic_hex_set_edge_projection 38 42 0 1 srf.00.3e20
    ic_hex_set_edge_projection 22 38 0 1 srf.00.3e20
    ic_hex_set_edge_projection 22 26 0 1 srf.00.3e20
    ic_hex_set_edge_projection 26 42 0 1 srf.00.3e20

    # Snap Edges to Associated Curves
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # Add Blocks and faces to be used in O-Grid
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 27

    ic_hex_mark_blocks face_neighbors corners { 21 37 25 41 } { 22 38 26 42 }

    # Create O Grid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN -version 50

    # Associate vertices with control circles
    ic_hex_set_node_projection 91 crv.11
    ic_hex_set_node_projection 81 crv.11
    ic_hex_set_node_projection 86 crv.11
    ic_hex_set_node_projection 96 crv.11

    ic_hex_set_node_projection 82 crv.12
    ic_hex_set_node_projection 92 crv.12
    ic_hex_set_node_projection 97 crv.12
    ic_hex_set_node_projection 87 crv.12

    ic_hex_set_node_projection 93 crv.13
    ic_hex_set_node_projection 83 crv.13
    ic_hex_set_node_projection 88 crv.13
    ic_hex_set_node_projection 98 crv.13

    # Snap vertices to control circles
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 91 n $ogrid_diffring_layern h1 $ogrid_diffring_initheight h2rel 0.0 r1 $ogrid_diffring_expansionrate r2 2 lmax 0 exp1 copy_to_parallel unlocked

    # Set center block element spacing
    ic_hex_set_mesh 91 96 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 91 81 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

    # Set number of sweeps
    ic_hex_set_mesh 41 74 n $ogrid_inlet_sweepn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 42 74 n $ogrid_diff_sweepn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

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

    # Associate Edges to Curves
    ic_hex_set_edge_projection 37 41 0 1 srf.00.6e30
    ic_hex_set_edge_projection 21 37 0 1 srf.00.6e30
    ic_hex_set_edge_projection 21 25 0 1 srf.00.6e30
    ic_hex_set_edge_projection 25 41 0 1 srf.00.6e30

    ic_hex_set_edge_projection 38 42 0 1 srf.00.7e34
    ic_hex_set_edge_projection 22 38 0 1 srf.00.7e34
    ic_hex_set_edge_projection 22 26 0 1 srf.00.7e34
    ic_hex_set_edge_projection 26 42 0 1 srf.00.7e34

    # Snap Edges to Associated Curves
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # Select Blocks and Faces for Ogrid
    ic_hex_mark_blocks superblock 13

    ic_hex_mark_blocks face_neighbors corners { 21 37 25 41 } { 22 38 26 42 }


    # Create Ogrid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETWALLS OUTLETMAIN NONSLIPWALL INTERFACEDIFF -version 50

    # Split Ring blocks in half
    ic_hex_split_grid 37 73 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLETMAIN OUTLETWALLS NONSLIPWALL INTERFACEDIFF


    # Associate inner ring edges to diffuser outlet
    ic_hex_set_edge_projection 85 87 0 1 srf.00.3e20
    ic_hex_set_edge_projection 84 85 0 1 srf.00.3e20
    ic_hex_set_edge_projection 84 86 0 1 srf.00.3e20
    ic_hex_set_edge_projection 86 87 0 1 srf.00.3e20

    # Associate inner ring edges to plenum outlet control circle
    ic_hex_set_edge_projection 88 89 0 1 crv.14
    ic_hex_set_edge_projection 89 91 0 1 crv.14
    ic_hex_set_edge_projection 90 91 0 1 crv.14
    ic_hex_set_edge_projection 88 90 0 1 crv.14

    # Associate vertices to control circles
    ic_hex_set_node_projection 73 crv.13
    ic_hex_set_node_projection 65 crv.13
    ic_hex_set_node_projection 69 crv.13
    ic_hex_set_node_projection 77 crv.13
    
    ic_hex_set_node_projection 74 crv.15
    ic_hex_set_node_projection 66 crv.15
    ic_hex_set_node_projection 70 crv.15
    ic_hex_set_node_projection 78 crv.15

    # Snap associations to geometry
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLETWALLS OUTLETMAIN

    # Define inner ring inflation layers
    ic_hex_set_mesh 85 73 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 87 77 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 86 69 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked
    ic_hex_set_mesh 84 65 n $ogrid_pleninner_layern h1 $ogrid_pleninner_initheight h2rel 0.0 r1 $ogrid_pleninner_expansionrate r2 2 lmax 0 exp1 unlocked

    # Define outer ring inflation layering
    ic_hex_set_mesh 37 85 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 41 87 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 25 86 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked
    ic_hex_set_mesh 21 84 n $ogrid_plenouter_layern h1 0.0 h2 $ogrid_plenouter_initheight r1 2 r2 $ogrid_plenouter_expansionrate lmax 0 exp2 unlocked

    #### NOTE: The edges on the outlet face of the plenum are assumed to make automatic linear distribution

    # Define Center block element numbering
    ic_hex_set_mesh 73 65 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 73 77 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

    # Set number of sweeps and expansion settings
    ic_hex_set_mesh 41 42 n $ogrid_plenum_sweepn h1 $ogrid_plenum_sweepinit h2rel 0.0 r1 $ogrid_plenum_sweepexpanratio r2 0 lmax 0 geo1 copy_to_parallel unlocked
}   