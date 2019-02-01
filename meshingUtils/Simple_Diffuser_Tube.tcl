ic_unload_tetin
# v0.2.0
#==============Parameters
# Meta
set {mesh_option} 1
# 0 = Geometry Creation Only
# 1 = DiffuserBody


# Unload the geometry, blocking, and mesh
ic_uns_diag_reset_degen_min_max 
ic_hex_unload_blocking 
ic_delete_empty_parts 
ic_csystem_set_current global
ic_unload_tetin 
ic_empty_tetin 
ic_delete_empty_parts 
ic_unload_mesh
ic_delete_empty_parts 

###TODO 
# Make the outer plenum wall edges have geometric distribution





#                                                   c3
#                                        p5*------------------------*p6
#                                         /                         |
#                                        /                          |
#                                       /                           |
#                                 p3*  / c2                         |
#                        c1           /                             |
#               p1*-----------------*/                              |c4
#                 |                 ^p2,p4,c5                       |
#                 |                        *p13                     *p14
#               c0*p11              *p12                            |
#                 |                                                 |
#                 |                                                 |
# rot_axis-->   p0*-----------------*------*------------------------*p7
#                                   ^p22   ^p23

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

#### Meshing 
## Control Circle parameters
set {ccirc_inletr} 100
    # radius @ inlet face
set {ccirc_outletinner} 110
    # inner circle radius @ domain outlet
set {ccirc_outletouter} 330
    # outer circle radius @ domain outlet

## Sweep parameters
set {ogrid_inlet_sweepn} 80
    # number of sweeps for the domain inlet
set {ogrid_inlet_sweepr} 1.00001
    # geometric rate of increase for the domain inlet
set {ogrid_diff_sweepn} 120
    # number of sweeps for the diffuser
set {ogrid_diff_sweepr} 1.002
    # geometric rate of increase for the diffuser
set {ogrid_diff_sweepinit} 3.25
    # initial element length of sweep (set to 0.0 to use ratio)
set {ogrid_outlet_sweepn} 180
    # number of sweeps for the outlet
set {ogrid_outlet_sweepinit} 5
    # initial element length of sweep (set to 0.0 to use ratio instead)
set {ogrid_outlet_sweepr} 1.01
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

##FOR TET & O-GRID MESH
set {global_ref} 2
    # global reference size (not used as reference in this script)
set {global_max_abs} 4
    # absolute global size
set {walls_max_abs} 2
    # absolute maximum element size on wall
set {vol_expanratio} 1.1
    # expansion rate for volume element mesh

###########################################################
#                Calculation of Parameters

# Setting basic diffuser dimensions
set {in_len} [expr $in_len_multi * $in_r * 2]
set {out_len} [expr $out_len_multi * $in_r * 2]
set {dif_angrad} [expr $dif_ang*(3.141592653589793/180)]


# Setting control circle parameters
set {ccirc_diffinr} $ccirc_inletr
    # radius @ diffuser inlet face, same radius @ domain inlet face
set {ccirc_diffoutr} [expr $ccirc_diffinr * ($out_r / $in_r)]
    # radius @ diffuser outlet, expands with area expansion


# Setting the diffuser geometry point values
set {05_i} [expr ($out_r - $in_r - $trans_r * (1 - cos($dif_angrad))) / tan($dif_angrad) + $trans_r * sin($dif_angrad) + $in_len]
set {05_j} $out_r
set {06_i} [expr $05_i + $out_len]
set {06_j} $05_j
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
ic_curve arc_ctr_rad GEOM crv.05 "pnt.03 pnt.02 pnt.05 $trans_r 0 $dif_ang"
    # ^^make arc curve and associated point
ic_point curve_end GEOM pnt.04 {crv.05 ymax}
ic_point {} GEOM pnt.06 0,$06_j,$06_i
ic_point {} GEOM pnt.07 0,0,$06_i

# making Curves
ic_curve point GEOM crv.00 {pnt.00 pnt.01}
ic_curve point GEOM crv.01 {pnt.01 pnt.02}
ic_curve point GEOM crv.02 {pnt.04 pnt.05}
ic_curve point GEOM crv.03 {pnt.05 pnt.06}
ic_curve point GEOM crv.04 {pnt.06 pnt.07}

# make revolved surfaces
ic_geo_cre_srf_rev GEOM srf.00 {crv.00 crv.01 crv.05 crv.04 crv.03 crv.02} pnt.00 {0 0 1} 0 360 c 1
ic_geo_new_family DIFFUSER
ic_boco_set_part_color DIFFUSER
ic_geo_create_body {srf.00.1 srf.00.5 srf.00.4 srf.00.3 srf.00.2 srf.00} {} DIFFUSER

#Creating parts for the surfaces
ic_geo_set_part surface srf.00 INLET 0
ic_delete_empty_parts 
ic_geo_set_part surface srf.00.3 OUTLET 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.2 srf.00.1 srf.00.4 srf.00.5} WALLS 0
ic_delete_empty_parts 

# Setting Family meshing parameters
ic_geo_set_family_params WALLS prism 1 emax $walls_max_abs

###########################################################
#                Creating Control Circles

#
#                                       p13*                        *p14
#              p11*              p12*      |                        |
#                 |                 |      |                        |
#                 |c11           c12|      |c13                     |c14
# rot_axis-->   p0*-----------------*------*------------------------*p7
#                                   ^p22   ^p23

# # creating Perpendicular circle points
ic_point projcurv GEOM pnt.11 {GEOM.19 srf.00.1e12}
ic_point projcurv GEOM pnt.12 {GEOM.19 srf.00.1e10}
ic_point projcurv GEOM pnt.13 {GEOM.19 srf.00.4e23}
ic_point projcurv GEOM pnt.14 {GEOM.19 srf.00.3e19}

# create center point for transition circle
ic_point {} GEOM pnt.22 0,0,$in_len
ic_point {} GEOM pnt.23 0,0,$05_i


# Creating Control Circles
ic_curve arc_ctr_rad GEOM crv.11 "GEOM.19 GEOM.21 pnt.11 $ccirc_inletr 0 360"
ic_curve arc_ctr_rad GEOM crv.12 "pnt.22 GEOM.25 pnt.12 $ccirc_diffinr 0 360"
ic_curve arc_ctr_rad GEOM crv.13 "pnt.23 GEOM.38 pnt.13 $ccirc_diffoutr 0 360"
ic_curve arc_ctr_rad GEOM crv.14 "GEOM.32 GEOM.34 pnt.14 $ccirc_diffoutr 0 360"


### DIFFUSER=OctOgrid PLENUM=OctOgrid
##
###### NOT VALIDATED!!!!!!!
##
if {$mesh_option == 1} {
    ######### DIFFUSER BODY
    puts "Starting OGrid for Diffuser"
    # Make Initial Block
    ic_hex_initialize_blocking {surface srf.00 surface srf.00.3} DIFFUSER 0 101
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
    ic_hex_split_grid 37 38 curve:srf.00.1e10:0.6276098184223936 m GEOM DIFFUSER SHELL LUMP INLET OUTLET WALLS

    ic_hex_split_grid 70 38 curve:srf.00.4e23:0.6276098184223936 m GEOM DIFFUSER SHELL LUMP INLET OUTLET WALLS

    # Associate Edges with Curves
    ic_hex_set_edge_projection 21 37 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 25 0 1 srf.00.1e12
    ic_hex_set_edge_projection 25 41 0 1 srf.00.1e12
    ic_hex_set_edge_projection 37 41 0 1 srf.00.1e12
    ic_hex_set_edge_projection 69 70 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 73 0 1 srf.00.1e10
    ic_hex_set_edge_projection 73 74 0 1 srf.00.1e10
    ic_hex_set_edge_projection 70 74 0 1 srf.00.1e10
    ic_hex_set_edge_projection 85 86 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 89 0 1 srf.00.4e23
    ic_hex_set_edge_projection 89 90 0 1 srf.00.4e23
    ic_hex_set_edge_projection 86 90 0 1 srf.00.4e23
    ic_hex_set_edge_projection 22 38 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 26 0 1 srf.00.3e19
    ic_hex_set_edge_projection 26 42 0 1 srf.00.3e19
    ic_hex_set_edge_projection 38 42 0 1 srf.00.3e19

    # Snap Edges to Associated Curves
    ic_hex_project_to_surface INLET SHELL DIFFUSER GEOM OUTLET LUMP WALLS

    # Add Blocks and faces to be used in O-Grid
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 27
    ic_hex_mark_blocks superblock 28

    ic_hex_mark_blocks face_neighbors corners { 21 37 25 41 } { 22 38 26 42 }

    # Create O Grid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP INLET OUTLET WALLS -version 50

    # Associate vertices with control circles
    ic_hex_set_node_projection 97 crv.11
    ic_hex_set_node_projection 109 crv.11
    ic_hex_set_node_projection 115 crv.11
    ic_hex_set_node_projection 103 crv.11

    ic_hex_set_node_projection 98 crv.12
    ic_hex_set_node_projection 110 crv.12
    ic_hex_set_node_projection 116 crv.12
    ic_hex_set_node_projection 104 crv.12

    ic_hex_set_node_projection 99 crv.13
    ic_hex_set_node_projection 111 crv.13
    ic_hex_set_node_projection 117 crv.13
    ic_hex_set_node_projection 105 crv.13

    ic_hex_set_node_projection 100 crv.14
    ic_hex_set_node_projection 112 crv.14
    ic_hex_set_node_projection 118 crv.14
    ic_hex_set_node_projection 106 crv.14

    # Snap vertices to control circles
    ic_hex_project_to_surface INLET SHELL DIFFUSER GEOM OUTLET LUMP WALLS

    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 109 n $ogrid_diffring_layern h1 $ogrid_diffring_initheight h2rel 0.0 r1 $ogrid_diffring_expansionrate r2 2 lmax 0 exp1 copy_to_parallel unlocked

    # Set center block element spacing
    ic_hex_set_mesh 115 103 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 115 109 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

    # Set number of sweeps
    ic_hex_set_mesh 25 73 n $ogrid_inlet_sweepn h1 0.0 h2rel 0.0 r1 $ogrid_inlet_sweepr r2 2 lmax 0 geo1 copy_to_parallel unlocked
    ic_hex_set_mesh 73 89 n $ogrid_diff_sweepn h1 $ogrid_diff_sweepinit h2rel 0.0 r1 $ogrid_diff_sweepr r2 2 lmax 0 geo1 copy_to_parallel unlocked
    # ic_hex_set_mesh 73 89 n $ogrid_diff_sweepn h1 0.0 h2rel 0.0 r1 $ogrid_diff_sweepr r2 2 lmax 0 geo1 copy_to_parallel unlocked
    ic_hex_set_mesh 89 26 n $ogrid_outlet_sweepn h1 $ogrid_outlet_sweepinit h2rel 0.0 r1 2 r2 2 lmax 0 geo1 copy_to_parallel unlocked

    # Compute Premesh
    ic_hex_create_mesh GEOM DIFFUSER INLET OUTLET WALLS proj 2 dim_to_mesh 3

}
