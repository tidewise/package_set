if ENV['ROS_ROOT'] || ENV['ROS_PATH']
    Autoproj.error "you cannot build Rock with ROS_ROOT / ROS_PATH set. Unset it and try again"
    exit 1
end
