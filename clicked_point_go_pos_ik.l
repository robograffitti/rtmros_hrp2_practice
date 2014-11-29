#!/usr/bin/env roseus
(load "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2w-interface.l")
(ros::roseus "go_pos_point")
(ros::advertise "/go_pos_point" geometry_msgs::PointStamped 1)

(defun preparation
  ()
  (hrp2w-init)
  (objects *hrp2w*)
  (send *hrp2w* :reset-manip-pose)
  (send *hrp2w* :fix-leg-to-coords (make-coords))
  (send *hrp2w* :head-neck-p :joint-angle 15)
  (send *irtviewer* :draw-objects)
  )

(defun move-robot
  ()
  (format t "WARN: HRP2-w moves!!!!~%")
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
  (setq *rarm-end* (send *hrp2w* :rarm :end-coords :copy-worldcoords))
  (send *rarm-end* :locate (send *ik-target* :pos) :world)
  (send *rarm-end* :translate #f(0 0 0))

  ;; go-pos for *vmax*
  (setq x (- (elt (send *rarm-end* :pos) 0) 300))
  (setq y (elt (send *rarm-end* :pos) 1))
  (setq t (* 10 (norm (send *rarm-end* :pos)))) ;; duration depending on distance

  ;; PointStamped
  (setq header (instance std_msgs::header :init :stamp (ros::time-now) :frame_id "base_vmax"))
  (setq point (instance geometry_msgs::Point :init :x (* 0.001 x) :y (* 0.001 y) :z 0))
  (setq *point-stamped* (instance geometry_msgs::PointStamped :init :header header :point point))
  (ros::publish "/go_pos_point" *point-stamped*)

  (format t "Press ENTER to go pos at x=~Am y=~Am v=~Asec~%"
          (send *point-stamped* :point :x)
          (send *point-stamped* :point :y)
          (* 0.001 t))
  (read-line)

  (send *vmax* :go-pos-relative-unsafe x y 0 t)
  (send *vmax* :wait-interpolation)

  ;; need conditional branch if IK fails
  (send *hrp2w* :rarm :inverse-kinematics *rarm-end*
        :rotation-axis nil
        :debug-view t :torso nil
        :link-list (send *hrp2w* :link-list
                         (send *hrp2w* :rarm :end-coords :parent)
                         (car (send *hrp2w* :torso :links))))
  )
(setq *msg* nil)

(preparation)
(format t "Press y to reset-manip-pose!~%")
(setq ans (read-line)) ;; for safety
(if (or (equal ans "y") (equal ans "Y"))
    (move-robot))

(ros::roseus "clicked_point_go_pos_ik")
(ros::subscribe "clicked_point" geometry_msgs::PointStamped #'clicked-pt-cb)

(do-until-key
 (ros::spin-once)
 )