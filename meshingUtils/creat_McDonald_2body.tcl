ic_unload_tetin
# v0.2.0
#==============Parameters
# Meta
set {mesh_option} 2
# 1 = DiffuserBody
# 2 = PlenumMesh






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
    # multiplies by inlet diameter for in_len
set {out_len_multi} 6 
set {in_r} 25.4
set {out_r} 28.9604
set {dif_ang} 4.0 
set {trans_r} 20
set {out_expan_r_multi} 3
    # multiplies by inlet diameter

#### Meshing 
## FOR O-GRID MESHING
set {ogrid_separation_space} 10
    # Absolute size change of separation edge
set {ogrid_separation_layern} 50
    # number of layers in the separation space
set {ogrid_init_spacing} 0.00025
    # value of initial height layer relative to separation_space
set {ogrid_separation_rate} 1.2
    # expotential rate at which the layer size increases
set {ogrid_separation_space_PLEN} 45
    # Absolute size change of separation edge

##FOR TET & O-GRID MESH
set {global_ref} 2
    # global reference size (not used as reference in this script)
set {global_max_abs} 4
    # absolute global size
set {walls_max_abs} 2
    # absolute maximum element size on wall
set {vol_expanratio} 1.1
    # expansion rate for volume element mesh

##FOR TET MESH ONLY
set {prsm_numlayer} 20
    # number of prism layers
set {prsm_law} exponential
    # prism layer expansion rule
set {prsm_growthratio} 1.1
    # prism layer growth rate
set {prsm_initheight} .05
    # first layer height of prism

# Calculation of Parameters

set {in_len} [expr $in_len_multi * $in_r * 2]
set {out_len} [expr $out_len_multi * $in_r * 2]
set {out_expan_r} [expr $out_expan_r_multi * $in_r]

set {prsm_totheight} [expr $prsm_initheight * ( (1-pow($prsm_growthratio , $prsm_numlayer)) / (1-$prsm_growthratio) )]

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
ic_geo_set_part surface {srf.00.7 srf.00.8} OUTLET 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.6} NONSLIPWALL 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.5} INTERFACEDIFF 0
ic_delete_empty_parts 


# Global Meshing parameters
ic_set_meshing_params global 0 gref $global_ref gmax $global_max_abs gfast 0 gedgec 0.2 gnat 0 gcgap 1 gnatref 10

# Volume Inflation Layer meshing parameters
ic_set_meshing_params variable 0 tetra_verbose 1 tetra_expansion_factor $vol_expanratio

# Inflation Layer meshing parameters
ic_set_meshing_params prism 0 law $prsm_law layers $prsm_numlayer height $prsm_initheight ratio $prsm_growthratio total_height $prsm_totheight prism_height_limit 0 max_prism_height_ratio {} stair_step 1 auto_reduction 0 min_prism_quality 0.0099999998 max_prism_angle 180 fillet 0.1 tetra_smooth_limit 0.30000001 n_tetra_smoothing_steps 10 n_triangle_smoothing_steps 5
ic_set_meshing_params variable 0 tgrid_n_ortho_layers 0 tgrid_fix_first_layer 0 tgrid_gap_factor 0.5 tgrid_enhance_norm_comp 0 tgrid_enhance_offset_comp 0 tgrid_smoothing_level 1 tgrid_max_cap_skew 0.98 tgrid_max_cell_skew 0.90 tgrid_last_layer_aspect {} triangle_quality inscribed_area

# Setting Family meshing parameters
ic_geo_set_family_params WALLS prism 1 emax $walls_max_abs

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
    ic_hex_split_grid 25 26 curve:srf.00.1e12:0.1253280303717014 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET
    ic_hex_undo_major_end split_grid

    # Split down the middle
    ic_hex_split_grid 25 41 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET
    ic_hex_split_grid 21 25 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET

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
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLET

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
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET -version 50

    # Set Separation Distance of DIFFUSER OGrid
    ic_hex_rescale_ogrid 3 0 $ogrid_separation_space m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET abs

    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 151 n $ogrid_separation_layern h1rel $ogrid_init_spacing h2rel 0.0 r1 $ogrid_separation_rate r2 2 lmax 0 exp1 copy_to_parallel unlocked
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
    ic_hex_split_grid 21 25 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET
    ic_hex_split_grid 25 41 0.5 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET

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
    ic_hex_project_to_surface PLENUM NONSLIPWALL INLET LUMP GEOM DIFFUSER SHELL INTERFACEDIFF WALLS OUTLET

    # Select Blocks and Faces for Ogrid
    ic_hex_mark_blocks superblock 29
    ic_hex_mark_blocks superblock 27
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 28

    ic_hex_mark_blocks face_neighbors corners { 26 93 73 92 } { 42 93 74 92 } { 38 91 74 92 } { 22 91 73 92 } { 41 88 70 87 } { 37 86 70 87 } { 21 86 69 87 } { 25 88 69 87 }

    # Create Ogrid
    ic_hex_ogrid 1 m GEOM DIFFUSER SHELL LUMP PLENUM INLET WALLS OUTLET NONSLIPWALL INTERFACEDIFF -version 50



}   