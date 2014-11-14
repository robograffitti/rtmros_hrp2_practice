#!/usr/bin/env roseus
(defun tf-ik ()
  (setq *torso-co* (send (car send *hrp2w* :torso)) :copy-worldcoords)
  (setq *target-co*
        (send *tfl* :lookup-transform
              "CHEST_LINK_0"
              "/camera_remote/depth_registered/cluster_decomposeroutput01"
              (ros::time 0)))
  )