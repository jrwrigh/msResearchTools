ic_unload_tetin
#==============Parameters
# Meta
set {mesh_option} 0

# Geometry
set {in_len} 150
set {out_len} 200
set {in_r} 20
set {dif_len} 50
set {dif_ang} 5.0 
set {trans_r} 20

# Meshing 
set {global_ref} 1
set {global_max} 2
set {prsm_numlayer} 20
set {prsm_law} exponential
set {prsm_growthratio} 1.1
set {prsm_initheight} .05
set {walls_max} 2
set {vol_expanratio} 1.1

# Calculation of Parameters

set {prsm_totheight} [expr $prsm_initheight * ( (1-pow($prsm_growthratio , $prsm_numlayer)) / (1-$prsm_growthratio) )]

set {dif_angrad} [expr $dif_ang*(3.14159265/180)]
# set {03_i} [expr $in_len + $trans_r*(1-cos ($dif_angrad*0.5)) ]
# set {04_i} [expr $in_len + $trans_r*(1-cos ($dif_angrad)) ]
# set {03_j} [expr $in_r - $trans_r + $trans_r * sin($dif_angrad*0.5) ]
# set {04_j} [expr $in_r - $trans_r + $trans_r * sin($dif_angrad) ]
set {05_i} [expr $in_len + $dif_len]
set {05_j} [expr $in_r + $dif_len * tan($dif_angrad)]
set {06_i} [expr $05_i + $out_len]
set {06_j} $05_j
# set {ang_start} [expr 360 - $dif_ang]
set {ang_start} 353.0
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
# ic_point {} GEOM pnt.03 $03_i,$03_j,0
# ic_point {} GEOM pnt.04 $04_i,$04_j,0
ic_point {} GEOM pnt.06 $06_i,$06_j,0
ic_point {} GEOM pnt.07 $06_i,0,0
ic_curve point GEOM crv.00 {pnt.00 pnt.01}
ic_curve point GEOM crv.01 {pnt.01 pnt.02}
ic_curve point GEOM crv.02 {pnt.04 pnt.05}
ic_curve point GEOM crv.03 {pnt.05 pnt.06}
ic_curve point GEOM crv.04 {pnt.06 pnt.07}
# ic_curve arc GEOM crv.05 {pnt.02 pnt.03 pnt.04}
ic_geo_cre_srf_rev GEOM srf.00 {crv.00 crv.01 crv.05 crv.04 crv.03 crv.02} pnt.00 {1 0 0} 0 360 c 1
ic_geo_new_family BODY
ic_boco_set_part_color BODY
ic_geo_create_body {srf.00.1 srf.00.5 srf.00.4 srf.00.3 srf.00.2 srf.00} {} BODY
#Creating parts for the surfaces
ic_geo_set_part surface srf.00 INLET 0
ic_delete_empty_parts 
ic_geo_set_part surface srf.00.3 OUTLET 0
ic_delete_empty_parts 
ic_geo_set_part surface {srf.00.2 srf.00.1 srf.00.4 srf.00.5} WALLS 0
ic_delete_empty_parts 
# Global Meshing parameters
ic_set_meshing_params global 0 gref $global_ref gmax $global_max gfast 0 gedgec 0.2 gnat 0 gcgap 1 gnatref 10
# Volume Inflation Layer meshing parameters
ic_set_meshing_params variable 0 tetra_verbose 1 tetra_expansion_factor $vol_expanratio
# Inflation Layer meshing parameters
ic_set_meshing_params prism 0 law $prsm_law layers $prsm_numlayer height $prsm_initheight ratio $prsm_growthratio total_height $prsm_totheight prism_height_limit 0 max_prism_height_ratio {} stair_step 1 auto_reduction 0 min_prism_quality 0.0099999998 max_prism_angle 180 fillet 0.1 tetra_smooth_limit 0.30000001 n_tetra_smoothing_steps 10 n_triangle_smoothing_steps 5
ic_set_meshing_params variable 0 tgrid_n_ortho_layers 0 tgrid_fix_first_layer 0 tgrid_gap_factor 0.5 tgrid_enhance_norm_comp 0 tgrid_enhance_offset_comp 0 tgrid_smoothing_level 1 tgrid_max_cap_skew 0.98 tgrid_max_cell_skew 0.90 tgrid_last_layer_aspect {} triangle_quality inscribed_area
# Setting Family meshing parameters
ic_geo_set_family_params WALLS prism 1 emax 4
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
# elseif {$mesh_option == 2} {

# }
