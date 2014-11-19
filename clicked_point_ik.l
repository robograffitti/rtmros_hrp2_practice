#!/usr/bin/env roseus
(load "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2w-interface.l")
(defun preparation
  ()
  (hrp2w-init)
  (objects *hrp2w*)
  (send *hrp2w* :reset-manip-pose)
  (send *hrp2w* :fix-leg-to-coords (make-coords))
  (send *irtviewer* :draw-objects)

  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun clicked-pt-cb (msg)
  (setq *msg* msg)
  (setq *torso-co* (send (car (send *hrp2w* :torso)) :copy-worldcoords))
  (setq *clicked-pt* (make-coords))
  (send *clicked-pt* :locate (float-vector (* 1000 (send *msg* :point :x))
                                           (* 1000 (send *msg* :point :y))
                                           (* 1000 (send *msg* :point :z))))
  (setq *ik-target* (send *torso-co* :transform *clicked-pt*))
  (send *rarm-end* :locate (send *ik-target* :pos) :world)
  (send *rarm-end* :translate #f(0 0 0))
  (format t "~A~%" *rarm-end*)

  (send *hrp2w* :rarm :inverse-kinematics *rarm-end*
        :rotational-axis nil :debug-view t :torso nil)
  ;; (send *hrp2w* :rarm :inverse-kinematics *rarm-end*
  ;;       :rotational-axis nil :debug-view t :torso nil
  ;;       :link-list (send *hrp2w* :link-list
  ;;                        (send *hrp2w* :rarm :end-coords :parent)
  ;;                        (car (send *hrp2w* :torso :links)))

  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )
(setq *msg* nil)

(preparation)
(ros::roseus "clicked_point_ik")
(ros::subscribe "clicked_point" geometry_msgs::PointStamped #'cp-cb)

(do-until-key
 (ros::spin-once)
 )