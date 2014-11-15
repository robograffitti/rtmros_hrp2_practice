#!/usr/bin/env roseus
(load "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2w-interface.l")
;; (ros::roseus-add-msgs "tf2_msgs")

(defun practice-setup
  ()
  (hrp2w-init)
  (objects *hrp2w*)
  (send *hrp2w* :reset-manip-pose)
  (send *hrp2w* :fix-leg-to-coords (make-coords))
  (send *irtviewer* :draw-objects)

  (setq *co* (send (send *hrp2w* :larm :end-coords) :copy-worldcoords))
  (send *co* :translate #f(200 -350 0))
  (send *hrp2w* :larm :inverse-kinematics *co* :rotational-axis nil :debug-view t :torso t)
  )

;; (defun tf-cb (msg) (setq *msg* msg) (format t "In tf-callback ~%"))
;; (setq *msg* nil)
(defun cp-cb (msg)
  (setq *msg* msg)
  (setq *clicked-point* (float-vector (send *msg* :point :x)
                                      (send *msg* :point :y)
                                      (send *msg* :point :z)))
  (format t "~A~%" *clicked-point*)
  )
(setq *msg* nil)

(practice-setup)
(format t "Press Enter to send angle-vector to ~A.~%" *ri*)
(read-line) ;; or (do-until-key)
(send *ri* :angle-vector (send *hrp2w* :angle-vector) 3000)
(send *ri* :wait-interpolation)

(ros::roseus "tutorial_tf")
(setq *tfl* (instance ros::transform-listener :init))
;; unused subscriber
;; (ros::subscribe "tf" tf2_msgs::TFMessage #'tf-cb)
(ros::subscribe "clicked_point" geometry_msgs::PointStamped #'cp-cb)

(do-until-key
 ;; parent, child, ros::Time::now(), ros::Duration(1.0)
 ;; see tf/Tutorials (C++)
 (send *tfl* :wait-for-transform "/CHEST_LINK0" "/LARM_LINK7" (ros::time 0) 1)
 (setq *target-co* (send *tfl* :lookup-transform "/CHEST_LINK0" "/LARM_LINK7" (ros::time 0)))
 (setq *torso-co* (send (car (send *hrp2w* :torso)) :copy-worldcoords))
 (setq *ik-target* (send *torso-co* :transform *target-co*))
 (setq *rarm-end* (send *hrp2w* :rarm :end-coords :copy-worldcoords))
 (send *rarm-end* :locate (send *ik-target* :pos) :world)
 (send *rarm-end* :translate #f(200 -50 50))
 (format t "~A~%" *rarm-end*)

 ;; Add 1 more to check *ramr-end* is t or nil
 (when (send *hrp2w* :rarm :inverse-kinematics *rarm-end*
             :rotational-axis nil :debug-view t :torso nil
             :link-list (send *hrp2w* :link-list
                              (send *hrp2w* :rarm :end-coords :parent)
                              (car (send *hrp2w* :torso :links))))
   (format t "ik with tf is done.~%")
   (return nil))
 (ros::spin-once)
 )
(do-until-key
 
 (ros::spin-once))