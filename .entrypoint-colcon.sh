#!/bin/bash -e

. /opt/ros/rolling/setup.sh
colcon build --executor sequential --event-handlers console_direct+ || exec "$@"
exec "$@"
