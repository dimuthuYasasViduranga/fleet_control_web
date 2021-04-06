import VueRouter from 'vue-router';

import AssetAssignment from '../components/pages/asset_assignment/AssetAssignment.vue';
import AssetStatus from '../components/pages/asset_status/AssetStatus.vue';
import DeviceAssignment from '../components/pages/device_assignment/DeviceAssignment.vue';
import LocationAssignment from '../components/pages/location_assignment_2/LocationAssignment.vue';
import Operators from '../components/pages/operators/Operators.vue';
import ActivityLog from '../components/pages/activity_log/ActivityLog.vue';
import TimeAllocationPage from '../components/pages/time_allocation/TimeAllocationPage.vue';
import TimeAllocationReport from '../components/pages/time_allocation_report/TimeAllocationReport.vue';
import TimeCodeEditorPage from '../components/pages/time_code_editor/TimeCodeEditorPage.vue';
import MessageEditorPage from '../components/pages/message_editor/MessageEditorPage.vue';
import MineMap from '../components/pages/mine_map/MineMap.vue';
import RouteMapPage from '../components/pages/route_map/RouteMapPage.vue';
import OperatorMessages from '../components/pages/operator_messages/OperatorMessages.vue';
import DispatcherMessages from '../components/pages/dispatcher_messages/DispatcherMessages.vue';
import DispatchHistory from '../components/pages/dispatch_history/DispatchHistory.vue';
import Assignments from '../components/pages/assignments/Assignments.vue';
import EngineHours from '../components/pages/engine_hours/EngineHours.vue';
import CycleTally from '../components/pages/cycle_tally/CycleTally.vue';
import Debug from '../components/pages/debug/Debug.vue';
import Agents from '../components/pages/agents/Agents.vue';
import PreStartEditor from '../components/pages/pre_start_editor/PreStartEditor.vue';
import PreStartSubmissionsPage from '../components/pages/pre_start_submissions/PreStartSubmissionsPage.vue';

import HaulTruckIcon from '../components/icons/asset_icons/HaulTruck.vue';
import TabletIcon from '../components/icons/Tablet.vue';
import LocationIcon from '../components/icons/Location.vue';
import ManIcon from '../components/icons/Man.vue';
import ListIcon from '../components/icons/List.vue';
import LineIcon from '../components/icons/Line.vue';
import TimeIcon from '../components/icons/Time.vue';
import MapIcon from '../components/icons/Map.vue';
import BellIcon from '../components/icons/Bell.vue';
import PlaneEngineIcon from '../components/icons/PlaneEngine.vue';
import NestedListIcon from '../components/icons/NestedList.vue';
import BugIcon from '../components/icons/Bug.vue';
import DatabaseIcon from '../components/icons/Database.vue';
import ReportIcon from '../components/icons/Report.vue';
import ChatIcon from '../components/icons/Chat.vue';

import Vue from 'vue';

const DEFAULT_ROUTE = '/location_assignment';
const ASSET_TRUCK_VIEW_BOX = [0, 4, 34, 26];

Vue.use(VueRouter);

interface Route {
  name: string;
  path: string;
  component: object;
  icon: object;
}

interface RouteWithIconProps {
  name: string;
  path: string;
  component: object;
  icon: object;
  iconProps: object;
}

interface Redirect {
  path: string;
  redirect: string;
}

interface Gap {
  path: string;
  gap: true;
}

type Routes = Array<Route | RouteWithIconProps | Redirect | Gap>;

export default function setupRouter(whitelist: object[]): [Routes, VueRouter] {
  let routes: Routes = [
    {
      name: 'Asset Assignment',
      path: '/asset_assignment',
      component: AssetAssignment,
      icon: HaulTruckIcon,
      iconProps: {
        viewBox: ASSET_TRUCK_VIEW_BOX,
      },
    },
    {
      name: 'Location Assignment',
      path: '/location_assignment',
      component: LocationAssignment,
      icon: LocationIcon,
    },
    {
      name: 'Mine Map',
      path: '/mine_map',
      component: MineMap,
      icon: MapIcon,
    },
    {
      name: 'Route Map',
      path: '/route_map',
      component: RouteMapPage,
      icon: LineIcon,
    },
    { path: '/gap_1', gap: true },
    {
      name: 'Operators',
      path: '/operators',
      component: Operators,
      icon: ManIcon,
    },
    {
      name: 'Device Assignment',
      path: '/device_assignment',
      component: DeviceAssignment,
      icon: TabletIcon,
    },
    {
      name: 'Time Code Editor',
      path: '/time_code_editor',
      component: TimeCodeEditorPage,
      icon: NestedListIcon,
    },
    {
      name: 'Message Editor',
      path: '/message_editor',
      component: MessageEditorPage,
      icon: ChatIcon,
    },
    {
      name: 'Pre-Start Editor',
      path: '/pre_start_editor',
      component: PreStartEditor,
      icon: ReportIcon,
    },
    { path: '/gap_2', gap: true },
    {
      name: 'Asset Status',
      path: '/asset_status',
      component: AssetStatus,
      icon: HaulTruckIcon,
      iconProps: {
        viewBox: ASSET_TRUCK_VIEW_BOX,
      },
    },
    {
      name: 'Pre-Start Submissions',
      path: '/pre_start_submissions',
      component: PreStartSubmissionsPage,
      icon: ReportIcon,
    },
    {
      name: 'Engine Hours',
      path: '/engine_hours',
      component: EngineHours,
      icon: PlaneEngineIcon,
    },
    {
      name: 'Time Allocation',
      path: '/time_allocation',
      component: TimeAllocationPage,
      icon: TimeIcon,
    },
    {
      name: 'Time Allocation Report',
      path: '/time_allocation_report',
      component: TimeAllocationReport,
      icon: ReportIcon,
    },
    { path: '/gap_3', gap: true },
    {
      name: 'Cycle Tally',
      path: '/cycle_tally',
      component: CycleTally,
      icon: ListIcon,
    },
    { path: '/gap_4', gap: true },
    {
      name: 'Activity Log',
      path: '/activity_log',
      component: ActivityLog,
      icon: ListIcon,
    },
    {
      name: 'Operator Messages',
      path: '/operator_messages',
      component: OperatorMessages,
      icon: BellIcon,
    },
    {
      name: 'Dispatcher Messages',
      path: '/disptacher_messages',
      component: DispatcherMessages,
      icon: BellIcon,
    },
    {
      name: 'Dispatch History',
      path: '/dispatch_history',
      component: DispatchHistory,
      icon: BellIcon,
    },
    {
      name: 'Assignments',
      path: '/assignments',
      component: Assignments,
      icon: BellIcon,
    },
    {
      name: 'Debug',
      path: '/debug',
      component: Debug,
      icon: BugIcon,
    },
    {
      name: 'Agents',
      path: '/agents',
      component: Agents,
      icon: DatabaseIcon,
    },
  ];

  // @ts-ignore
  routes = routes.filter(r => r.gap === true || whitelist.includes(r.path));

  // set default page, or the first available
  if (routes.length !== 0) {
    if (routes.find(r => r.path === DEFAULT_ROUTE)) {
      routes.push({ path: '*', redirect: DEFAULT_ROUTE });
    } else {
      routes.push({ path: '*', redirect: routes[0].path });
    }
  }

  const router = new VueRouter({ routes });

  return [routes, router];
}
