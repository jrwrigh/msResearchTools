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

#                        c1       
#               p1*-----------------*p2
#                 |                 |
#                 |                 |
#               c0|                 | c2
#                 |                 |  
#                 |                 |  
# rot_axis-->   p0*-----------------*p3
#                         c3         

#### Geometry
set {in_len_multi}  4
    # multiplies by inlet diameter for diffuser/domain inlet length
set {in_r} 130
    # radius of diffuser/domain inlet

#### Meshing 
## Control Circle parameters
set {ccirc_inletr} 100
    # radius @ inlet face
set {ccirc_outletinner} 110
    # inner circle radius @ domain outlet

## Sweep parameters
set {ogrid_inlet_sweepn} 360
    # number of sweeps for the domain inlet
set {ogrid_inlet_sweepr} 1.000001
    # geometric rate of increase for the domain inlet

## FOR O-GRID MESHING
set {ogrid_center_elementn} 42
    # number of elements to put on one side of center octogon

set {ogrid_diffring_layern} 40
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

###################################
######## Calculation of Parameters
###################################

# Setting basic diffuser dimensions
set {in_len} [expr $in_len_multi * $in_r * 2]

# Setting control circle parameters
set {ccirc_diffinr} $ccirc_inletr
    # radius @ diffuser inlet face, same radius @ domain inlet face


# Setting the diffuser geometry point values
ic_geo_set_units mm
###
ic_geo_new_family GEOM
ic_boco_set_part_color GEOM
ic_empty_tetin
ic_point {} GEOM pnt.00 0,0,0
ic_point {} GEOM pnt.01 0,$in_r,0
ic_point {} GEOM pnt.02 0,$in_r,$in_len
ic_point {} GEOM pnt.03 0,0,$in_len
# making Curves
ic_curve point GEOM crv.00 {pnt.00 pnt.01}
ic_curve point GEOM crv.01 {pnt.01 pnt.02}
ic_curve point GEOM crv.02 {pnt.02 pnt.03}
ic_curve point GEOM crv.03 {pnt.03 pnt.00}
# make revolved surfaces
ic_geo_cre_srf_rev GEOM srf.00 {crv.00 crv.01 crv.02} pnt.00 {0 0 1} 0 360 c 1
ic_geo_new_family DIFFUSER
ic_boco_set_part_color DIFFUSER
ic_geo_create_body {srf.00 srf.00.1 srf.00.2} {} DIFFUSER

#Creating parts for the surfaces
ic_geo_set_part surface srf.00 INLET 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.1} WALL 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.2} OUTLET 0
ic_delete_empty_parts 

# Setting Family meshing parameters
ic_geo_set_family_params WALL prism 1 emax $walls_max_abs

##############################
#### Creating control circles
##############################

#creating Perpendicular circle points
ic_point projcurv GEOM pnt.11 {GEOM.9 srf.00.1e10}
ic_point projcurv GEOM pnt.12 {GEOM.9 srf.00.1e8}

## Creating Control Circles
ic_curve arc_ctr_rad GEOM crv.04 "GEOM.9 GEOM.11 pnt.11 $ccirc_inletr 0 360"
ic_curve arc_ctr_rad GEOM crv.05 "GEOM.18 GEOM.15 pnt.12 $ccirc_diffinr 0 360"

### DIFFUSER=OctOgrid PLENUM=OctOgrid
##
###### NOT VALIDATED!!!!!!!
##
if {$mesh_option == 1} {
    ######### DIFFUSER BODY
    # Make Initial Block
    ic_hex_initialize_blocking {surface srf.00 surface srf.00.1 surface srf.00.2} DIFFUSER 0 101
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

    # Associate Edges with Curves
    ic_hex_set_edge_projection 25 41 0 1 srf.00.1e10
    ic_hex_set_edge_projection 37 41 0 1 srf.00.1e10
    ic_hex_set_edge_projection 21 37 0 1 srf.00.1e10
    ic_hex_set_edge_projection 21 25 0 1 srf.00.1e10
    ic_hex_set_edge_projection 26 42 0 1 srf.00.1e8
    ic_hex_set_edge_projection 38 42 0 1 srf.00.1e8
    ic_hex_set_edge_projection 22 26 0 1 srf.00.1e8
    ic_hex_set_edge_projection 22 38 0 1 srf.00.1e8

    # Snap Edges to Associated Curves
    ic_hex_project_to_surface WALL INLET SHELL DIFFUSER GEOM OUTLET LUMP

    # Add Blocks and faces to be used in O-Grid
    ic_hex_mark_blocks superblock 13

    ic_hex_mark_blocks face_neighbors corners { 21 37 25 41 } { 22 38 26 42 }

    # Create O Grid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP INLET WALL OUTLET -version 50

    # Associate vertices with control circles
    ic_hex_set_node_projection 77 crv.04
    ic_hex_set_node_projection 69 crv.04
    ic_hex_set_node_projection 65 crv.04
    ic_hex_set_node_projection 73 crv.04

    ic_hex_set_node_projection 78 crv.05
    ic_hex_set_node_projection 70 crv.05
    ic_hex_set_node_projection 66 crv.05
    ic_hex_set_node_projection 74 crv.05

    # Snap vertices to control circles
    ic_hex_project_to_surface WALL INLET SHELL DIFFUSER GEOM OUTLET LUMP

    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 73 n $ogrid_diffring_layern h1 $ogrid_diffring_initheight h2rel 0.0 r1 $ogrid_diffring_expansionrate r2 2 lmax 0 exp1 copy_to_parallel unlocked

    # Set center block element spacing
    ic_hex_set_mesh 73 77 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked
    ic_hex_set_mesh 69 77 n $ogrid_center_elementn h1 0.0 h2rel 0.0 r1 2 r2 2 lmax 0 default copy_to_parallel unlocked

    # Set number of sweeps
    ic_hex_set_mesh 25 26 n $ogrid_inlet_sweepn h1 0.0 h2rel 0.0 r1 $ogrid_inlet_sweepr r2 2 lmax 0 geo1 copy_to_parallel unlocked

}