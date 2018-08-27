ic_unload_tetin
# v0.2.0
#==============Parameters
# Meta
set {mesh_option} 4


#                                                   c3
#                                       p5*-------------------------*p6
#                                        /                          |
#                                       /                           |
#                                 p3*  / c2                         |
#                        c1           /                             |
#               p1*-----------------*/                              |
#                 |                 ^p2,p4,c5                       |c4
#                 |                                                 |
#               c0|                                                 |
#                 |                                                 |
#                 |                                                 |
# rot_axis-->   p0*-------------------------------------------------*p7


#### Geometry
set {in_len_multi}  3
    # multiplies by inlet diameter for in_len
set {out_len_multi} 12 
set {in_r} 25.4
set {out_r} 28.9604
set {dif_ang} 4.0 
set {trans_r} 20

#### Meshing 
## FOR O-GRID MESHING
set {ogrid_separation_space} 10
    # Absolute size change of separation edge
set {ogrid_separation_layern} 80
    # number of layers in the separation space
set {ogrid_init_spacing} 0.00164
    # value of initial height layer relative to separation_space
set {ogrid_separation_rate} 1.2
    # expotential rate at which the layer size increases

## FOR O-GRID INLET REFINEMENT
set {ogrid_inre_depth} 20
    # Inlet refinement block depth
set {ogrid_inre_layern} 25
    # Inlet refinement element count
set {ogrid_inre_initialh} 0.025
    # Inlet refinement initial height
set {ogrid_inre_rate} 1.2
    # Inlet refinement expansion rate

##FOR TET & O-GRID MESH
set {global_ref} 3
    # global reference size (not used as reference in this script)
set {global_max_abs} 4
    # absolute global size
set {walls_max_abs} 3
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

set {prsm_totheight} [expr $prsm_initheight * ( (1-pow($prsm_growthratio , $prsm_numlayer)) / (1-$prsm_growthratio) )]

set {dif_angrad} [expr $dif_ang*(3.141592653589793/180)]
set {05_i} [expr ($out_r - $in_r - $trans_r * (1 - cos($dif_angrad))) / tan($dif_angrad) + $trans_r * sin($dif_angrad) + $in_len]
set {05_j} $out_r
# set {05_j} [expr $in_r + $dif_len * tan($dif_angrad)]
set {06_i} [expr $05_i + $out_len]
set {06_j} $05_j
ic_geo_set_units mm
###
ic_geo_new_family GEOM
ic_boco_set_part_color GEOM
ic_empty_tetin
ic_point {} GEOM pnt.00 0,0,0
ic_point {} GEOM pnt.01 0,$in_r,0
ic_point {} GEOM pnt.02 $in_len,$in_r,0
ic_point {} GEOM pnt.03 $in_len,[expr $in_r + $trans_r],0
ic_point {} GEOM pnt.05 $05_i,$05_j,0
ic_curve arc_ctr_rad GEOM crv.05 "pnt.03 pnt.02 pnt.05 $trans_r 0 $dif_ang"
ic_point curve_end GEOM pnt.04 {crv.05 ymax}
ic_point {} GEOM pnt.06 $06_i,$06_j,0
ic_point {} GEOM pnt.07 $06_i,0,0
ic_curve point GEOM crv.00 {pnt.00 pnt.01}
ic_curve point GEOM crv.01 {pnt.01 pnt.02}
ic_curve point GEOM crv.02 {pnt.04 pnt.05}
ic_curve point GEOM crv.03 {pnt.05 pnt.06}
ic_curve point GEOM crv.04 {pnt.06 pnt.07}
ic_geo_cre_srf_rev GEOM srf.00 {crv.00 crv.01 crv.05 crv.04 crv.03 crv.02} pnt.00 {1 0 0} 0 360 c 1
ic_geo_new_family BODY
ic_boco_set_part_color BODY
ic_geo_create_body {srf.00.1 srf.00.5 srf.00.4 srf.00.3 srf.00.2 srf.00} {} BODY

# Rotationing the part to be axial with Z
ic_move_geometry curve names {srf.00.3e19 srf.00.2e14 srf.00.1e12 srf.00.1e10 crv.04 crv.03 crv.02 crv.01 crv.00 crv.05 srf.00.4e23} rotate 270 rotate_axis {0 1 0} cent {0 0 0}
ic_move_geometry body names BODY.0 rotate 270 rotate_axis {0 1 0} cent {0 0 0}

#Creating parts for the surfaces
ic_geo_set_part surface srf.00 INLET 0
ic_delete_empty_parts 
ic_geo_set_part surface srf.00.3 OUTLET 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.2 srf.00.1 srf.00.4 srf.00.5} WALLS 0
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

#### Create mesh
if {$mesh_option == 1} {
    ic_set_global geo_cad 0.3 toler

    # Create the surface mesh
    ic_quad2 what surfaces entities {} element 3 proj 1 conver 0.025 geo_tol 0 ele_tol 0.3 dev 0.0 improvement 1 block 0.2 bunch 0 debug 0 adjust_nodes 0 adjust_nodes_max 0 try_harder 1 error_subset Failed_surfaces pattern 150 big 1 board 0 remove_old -1 inner 0 simple_offset 0 enn 0 b_smooth 0 time_max 0 ele_max 0 four 0 merge_dormant 1 max_length 0.0 max_area 0.0 min_angle 0.0 max_nodes 0 max_elements 0 smoothdormant 0 breakpoint 0 freeb 0 n_threads 0 snorm 1 shape 0

    # Run the Advancing Front mesher in batch mode
    ic_uns_subset_delete afmesh_errors
    ic_save_unstruct afmesh_temp0.uns 1 {} {} {}
    ic_run_afmesh afmesh_temp0.uns ./afmesh_mesh.uns geometry 0 proximity 0 tetexpand 1.2 family BODY bgmesh 0 show_progress 1 errors afmesh_errors verbose 1
    ic_unload_mesh
    ic_delete_empty_parts
    ic_uns_load {"afmesh_mesh.uns"} 3 1 {} 0
    ic_boco_solver
    ic_uns_update_family_type visible {INLET SHELL GEOM OUTLET ORFN LUMP BODY WALLS} {!NODE LINE_2 TRI_3 !TETRA_4} update 0
    ic_boco_clear_icons
    ic_uns_list_material_families
    ic_flood_fill_mesh 0 1
    ic_save_unstruct temp_prism0.uns
    ic_rm prism.uns
    ic_run_prism {} temp_prism0.uns prism.uns params .prism_params log prism_cmd.log n_processors 1 first_layer_smoothing_steps 1 fillet 0.1 max_prism_angle 180 min_prism_quality 0.0099999998 tetra_smooth_limit 0.30000001 family WALLS
    ic_rm temp_prism0.uns
    ic_unload_mesh 
    ic_delete_empty_parts 
    ic_uns_load prism.uns 3 0 {} 2
    ic_delete_empty_parts
    ic_set_global geo_cad 0.3 toler
    }

### For block instead of unstructured tet mesh
if {$mesh_option == 2} {
    # Make Initial block
    ic_hex_unload_blocking 
    ic_hex_initialize_blocking {surface srf.00.4 surface srf.00.3 surface srf.00.2 surface srf.00.1 surface srf.00 surface srf.00.5} BODY 0 101
    ic_hex_unblank_blocks 
    ic_hex_multi_grid_level 0
    ic_hex_projection_limit 0
    ic_hex_default_bunching_law default 2.0
    ic_hex_floating_grid off
    ic_hex_transfinite_degree 1
    ic_hex_unstruct_face_type one_tri
    ic_hex_set_unstruct_face_method uniform_quad
    ic_hex_set_n_tetra_smoothing_steps 20
    ic_hex_error_messages off_minor

    # Split Block apart
    ic_hex_mark_blocks unmark
    ic_hex_mark_blocks unmark
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 41 42 curve:srf.00.1e10:0.8795489503190525 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid
    ic_undo_group_end 
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 74 42 curve:srf.00.4e23:0.8795489503190525 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid

    # Associate block edges with curves
    ic_hex_set_edge_projection 37 41 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 37 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 25 0 1 srf.00.1e12
    ic_hex_set_edge_projection 25 41 0 1 srf.00.1e12
    ic_hex_find_comp_curve srf.00.1e10
    ic_hex_set_edge_projection 70 74 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 70 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 73 0 1 srf.00.1e10
    ic_hex_set_edge_projection 73 74 0 1 srf.00.1e10
    ic_hex_find_comp_curve srf.00.4e23
    ic_hex_set_edge_projection 86 90 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 86 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 89 0 1 srf.00.4e23
    ic_hex_set_edge_projection 89 90 0 1 srf.00.4e23
    ic_hex_find_comp_curve srf.00.3e19
    ic_hex_set_edge_projection 38 42 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 38 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 26 0 1 srf.00.3e19
    ic_hex_set_edge_projection 26 42 0 1 srf.00.3e19

    # Snap verticies to curves
    ic_hex_project_to_surface INLET SHELL GEOM OUTLET LUMP BODY WALLS

    # select blocks for O-Grid
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 28
    ic_hex_mark_blocks superblock 27

    # select faces for O-Grid
    ic_hex_mark_blocks face_neighbors corners { 21 37 25 41 } { 22 38 26 42 }

    # create O-Grid
    ic_hex_ogrid 1 m GEOM BODY SHELL LUMP INLET OUTLET WALLS -version 50
    ic_hex_mark_blocks unmark


    # adjust O-Grid scale
    ic_hex_rescale_ogrid 3 0 $ogrid_separation_space m GEOM BODY SHELL LUMP INLET OUTLET WALLS abs


    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 109 n $ogrid_separation_layern h1rel $ogrid_init_spacing h2rel 0.0 r1 $ogrid_separation_rate r2 2 lmax 0 exp1 copy_to_parallel unlocked

}

### For octohedral o-grid instead of square o-grid
if {$mesh_option == 3} {
    # Make Initial block
    ic_hex_unload_blocking 
    ic_hex_initialize_blocking {surface srf.00.4 surface srf.00.3 surface srf.00.2 surface srf.00.1 surface srf.00 surface srf.00.5} BODY 0 101
    ic_hex_unblank_blocks 
    ic_hex_multi_grid_level 0
    ic_hex_projection_limit 0
    ic_hex_default_bunching_law default 2.0
    ic_hex_floating_grid off
    ic_hex_transfinite_degree 1
    ic_hex_unstruct_face_type one_tri
    ic_hex_set_unstruct_face_method uniform_quad
    ic_hex_set_n_tetra_smoothing_steps 20
    ic_hex_error_messages off_minor

    # Split Block apart
        # Major splits (for the diameter transitions)
    ic_hex_mark_blocks unmark
    ic_hex_mark_blocks unmark
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 41 42 curve:srf.00.1e10:0.8795489503190525 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid
    ic_undo_group_end 
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 74 42 curve:srf.00.4e23:0.8795489503190525 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid

        # Splits down the middle
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 37 41 GEOM.19 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid
    ic_undo_group_end 
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 25 41 GEOM.19 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid

    # Associate block edges with curves
    ic_hex_set_edge_projection 37 102 0 1 srf.00.1e12
    ic_hex_set_edge_projection 126 37 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 126 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 101 0 1 srf.00.1e12
    ic_hex_set_edge_projection 101 25 0 1 srf.00.1e12
    ic_hex_set_edge_projection 25 128 0 1 srf.00.1e12
    ic_hex_set_edge_projection 128 41 0 1 srf.00.1e12
    ic_hex_set_edge_projection 102 41 0 1 srf.00.1e12
    ic_undo_group_end 
    ic_hex_find_comp_curve srf.00.1e10
    ic_undo_group_begin 
    ic_hex_set_edge_projection 70 106 0 1 srf.00.1e10
    ic_hex_set_edge_projection 131 70 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 131 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 105 0 1 srf.00.1e10
    ic_hex_set_edge_projection 105 73 0 1 srf.00.1e10
    ic_hex_set_edge_projection 73 133 0 1 srf.00.1e10
    ic_hex_set_edge_projection 133 74 0 1 srf.00.1e10
    ic_hex_set_edge_projection 106 74 0 1 srf.00.1e10
    ic_undo_group_end 
    ic_hex_find_comp_curve srf.00.4e23
    ic_undo_group_begin 
    ic_hex_set_edge_projection 86 110 0 1 srf.00.4e23
    ic_hex_set_edge_projection 136 86 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 136 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 109 0 1 srf.00.4e23
    ic_hex_set_edge_projection 89 138 0 1 srf.00.4e23
    ic_hex_set_edge_projection 109 89 0 1 srf.00.4e23
    ic_hex_set_edge_projection 138 90 0 1 srf.00.4e23
    ic_hex_set_edge_projection 110 90 0 1 srf.00.4e23
    ic_undo_group_end 
    ic_hex_find_comp_curve srf.00.3e19
    ic_undo_group_begin 
    ic_hex_set_edge_projection 38 114 0 1 srf.00.3e19
    ic_hex_set_edge_projection 141 38 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 141 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 113 0 1 srf.00.3e19
    ic_hex_set_edge_projection 113 26 0 1 srf.00.3e19
    ic_hex_set_edge_projection 26 143 0 1 srf.00.3e19
    ic_hex_set_edge_projection 114 42 0 1 srf.00.3e19
    ic_hex_set_edge_projection 143 42 0 1 srf.00.3e19


    # Snap verticies to curves
    ic_hex_project_to_surface INLET SHELL GEOM OUTLET LUMP BODY WALLS

    # select blocks for O-Grid
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 27
    ic_hex_mark_blocks superblock 28
    ic_hex_mark_blocks superblock 29
    ic_hex_mark_blocks superblock 30
    ic_hex_mark_blocks superblock 31
    ic_hex_mark_blocks superblock 32
    ic_hex_mark_blocks superblock 33
    ic_hex_mark_blocks superblock 34
    ic_hex_mark_blocks superblock 35
    ic_hex_mark_blocks superblock 36
    ic_hex_mark_blocks superblock 37

    # select faces for O-Grid
    ic_hex_mark_blocks face_neighbors corners { 86 136 110 137 } { 22 141 113 142 } { 21 126 101 127 } { 37 126 102 127 } { 41 128 102 127 } { 25 128 101 127 } { 38 141 114 142 } { 42 143 114 142 } { 26 143 113 142 }

    # create O-Grid
    ic_hex_ogrid 1 m GEOM BODY SHELL LUMP INLET OUTLET WALLS -version 50
    ic_hex_mark_blocks unmark

    # adjust O-Grid scale
    ic_hex_rescale_ogrid 3 0 $ogrid_separation_space m GEOM BODY SHELL LUMP INLET OUTLET WALLS abs

    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 181 n $ogrid_separation_layern h1rel $ogrid_init_spacing h2rel 0.0 r1 $ogrid_separation_rate r2 2 lmax 0 exp1 copy_to_parallel unlocked

}

### For octogrid with refined inlet area
if {$mesh_option == 4} {
    # Make Initial block
    ic_hex_unload_blocking 
    ic_hex_initialize_blocking {surface srf.00.4 surface srf.00.3 surface srf.00.2 surface srf.00.1 surface srf.00 surface srf.00.5} BODY 0 101
    ic_hex_unblank_blocks 
    ic_hex_multi_grid_level 0
    ic_hex_projection_limit 0
    ic_hex_default_bunching_law default 2.0
    ic_hex_floating_grid off
    ic_hex_transfinite_degree 1
    ic_hex_unstruct_face_type one_tri
    ic_hex_set_unstruct_face_method uniform_quad
    ic_hex_set_n_tetra_smoothing_steps 20
    ic_hex_error_messages off_minor

    # Split Block apart
        # Major splits (for the diameter transitions)
    ic_hex_mark_blocks unmark
    ic_hex_mark_blocks unmark
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 41 42 curve:srf.00.1e10:0.8795489503190525 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid
    ic_undo_group_end 
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 74 42 curve:srf.00.4e23:0.8795489503190525 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid

        # Splits down the middle
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 37 41 GEOM.19 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid
    ic_undo_group_end 
    ic_undo_group_begin 
    ic_hex_undo_major_start split_grid
    ic_hex_split_grid 25 41 GEOM.19 m GEOM BODY SHELL LUMP INLET OUTLET WALLS
    ic_hex_undo_major_end split_grid

    # Associate block edges with curves
    ic_hex_set_edge_projection 37 102 0 1 srf.00.1e12
    ic_hex_set_edge_projection 126 37 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 126 0 1 srf.00.1e12
    ic_hex_set_edge_projection 21 101 0 1 srf.00.1e12
    ic_hex_set_edge_projection 101 25 0 1 srf.00.1e12
    ic_hex_set_edge_projection 25 128 0 1 srf.00.1e12
    ic_hex_set_edge_projection 128 41 0 1 srf.00.1e12
    ic_hex_set_edge_projection 102 41 0 1 srf.00.1e12
    ic_undo_group_end 
    ic_hex_find_comp_curve srf.00.1e10
    ic_undo_group_begin 
    ic_hex_set_edge_projection 70 106 0 1 srf.00.1e10
    ic_hex_set_edge_projection 131 70 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 131 0 1 srf.00.1e10
    ic_hex_set_edge_projection 69 105 0 1 srf.00.1e10
    ic_hex_set_edge_projection 105 73 0 1 srf.00.1e10
    ic_hex_set_edge_projection 73 133 0 1 srf.00.1e10
    ic_hex_set_edge_projection 133 74 0 1 srf.00.1e10
    ic_hex_set_edge_projection 106 74 0 1 srf.00.1e10
    ic_undo_group_end 
    ic_hex_find_comp_curve srf.00.4e23
    ic_undo_group_begin 
    ic_hex_set_edge_projection 86 110 0 1 srf.00.4e23
    ic_hex_set_edge_projection 136 86 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 136 0 1 srf.00.4e23
    ic_hex_set_edge_projection 85 109 0 1 srf.00.4e23
    ic_hex_set_edge_projection 89 138 0 1 srf.00.4e23
    ic_hex_set_edge_projection 109 89 0 1 srf.00.4e23
    ic_hex_set_edge_projection 138 90 0 1 srf.00.4e23
    ic_hex_set_edge_projection 110 90 0 1 srf.00.4e23
    ic_undo_group_end 
    ic_hex_find_comp_curve srf.00.3e19
    ic_undo_group_begin 
    ic_hex_set_edge_projection 38 114 0 1 srf.00.3e19
    ic_hex_set_edge_projection 141 38 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 141 0 1 srf.00.3e19
    ic_hex_set_edge_projection 22 113 0 1 srf.00.3e19
    ic_hex_set_edge_projection 113 26 0 1 srf.00.3e19
    ic_hex_set_edge_projection 26 143 0 1 srf.00.3e19
    ic_hex_set_edge_projection 114 42 0 1 srf.00.3e19
    ic_hex_set_edge_projection 143 42 0 1 srf.00.3e19


    # Snap verticies to curves
    ic_hex_project_to_surface INLET SHELL GEOM OUTLET LUMP BODY WALLS

    # select blocks for O-Grid
    ic_hex_mark_blocks superblock 13
    ic_hex_mark_blocks superblock 27
    ic_hex_mark_blocks superblock 28
    ic_hex_mark_blocks superblock 29
    ic_hex_mark_blocks superblock 30
    ic_hex_mark_blocks superblock 31
    ic_hex_mark_blocks superblock 32
    ic_hex_mark_blocks superblock 33
    ic_hex_mark_blocks superblock 34
    ic_hex_mark_blocks superblock 35
    ic_hex_mark_blocks superblock 36
    ic_hex_mark_blocks superblock 37

    # select faces for O-Grid
    ic_hex_mark_blocks face_neighbors corners { 86 136 110 137 } { 22 141 113 142 } { 21 126 101 127 } { 37 126 102 127 } { 41 128 102 127 } { 25 128 101 127 } { 38 141 114 142 } { 42 143 114 142 } { 26 143 113 142 }

    # create O-Grid
    ic_hex_ogrid 1 m GEOM BODY SHELL LUMP INLET OUTLET WALLS -version 50
    ic_hex_mark_blocks unmark

    # adjust O-Grid scale
    ic_hex_rescale_ogrid 3 0 $ogrid_separation_space m GEOM BODY SHELL LUMP INLET OUTLET WALLS abs


    # Split block for inlet refinement
    ic_hex_split_grid 25 73 abs:$ogrid_inre_depth m GEOM BODY SHELL LUMP INLET OUTLET WALLS

    # Inlet refinement settings
    ic_hex_set_mesh 25 219 n $ogrid_inre_layern h1rel $ogrid_inre_initialh h2rel 0.15 r1 $ogrid_inre_rate r2 2 lmax 3 exp1 copy_to_parallel unlocked


    # SPACING IS FRACTION OF EDGE LENGTH, NOT ABSOLUTE VALUE
    # set edge mesh criteria
    ic_hex_set_mesh 37 181 n $ogrid_separation_layern h1rel $ogrid_init_spacing h2rel 0.0 r1 $ogrid_separation_rate r2 2 lmax 0 exp1 copy_to_parallel unlocked


}
