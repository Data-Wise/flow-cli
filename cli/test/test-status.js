/**
 * Test Status Adapter and API
 *
 * Simple test script to verify status reading functionality
 */

const statusAdapter = require('../adapters/status');
const statusAPI = require('../api/status-api');

async function testStatusAdapter() {
  console.log('🧪 Testing Status Adapter...\n');

  try {
    // Test 1: Get current session
    console.log('Test 1: Get Current Session');
    const session = await statusAdapter.getCurrentSession();
    if (session) {
      console.log('✅ Active session found:');
      console.log(`   Project: ${session.project}`);
      console.log(`   Duration: ${session.duration_minutes} minutes`);
      console.log(`   Editor: ${session.editor || 'unknown'}`);
    } else {
      console.log('ℹ️  No active session');
    }
    console.log('');

    // Test 2: Get project status
    console.log('Test 2: Get Project Status');
    const projectStatus = await statusAdapter.getProjectStatus(process.cwd());
    if (projectStatus.error) {
      console.log(`⚠️  ${projectStatus.error}`);
    } else {
      console.log('✅ Project status found:');
      console.log(`   Location: ${projectStatus.location}`);
      console.log(`   Last Updated: ${projectStatus.lastUpdated}`);
      console.log(`   Progress bars: ${projectStatus.progress.length}`);
      if (projectStatus.progress.length > 0) {
        projectStatus.progress.forEach(p => {
          console.log(`     - ${p.phase}: ${p.name} (${p.progress}%) ${p.status}`);
        });
      }
    }
    console.log('');

    // Test 3: Get complete status
    console.log('Test 3: Get Complete Status');
    const complete = await statusAdapter.getCompleteStatus();
    console.log('✅ Complete status retrieved');
    console.log(`   Session active: ${complete.session !== null}`);
    console.log(`   Project has status: ${!complete.project.error}`);
    console.log('');

    // Test 4: Check if session is active
    console.log('Test 4: Check Session Active');
    const isActive = await statusAdapter.isSessionActive();
    console.log(`✅ Session active: ${isActive}`);
    console.log('');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

async function testStatusAPI() {
  console.log('🧪 Testing Status API...\n');

  try {
    // Test 1: Get dashboard data
    console.log('Test 1: Get Dashboard Data');
    const dashboard = await statusAPI.getDashboardData();
    console.log('✅ Dashboard data retrieved:');
    console.log(`   Session active: ${dashboard.session.active}`);
    if (dashboard.session.active) {
      console.log(`   Project: ${dashboard.session.project}`);
      console.log(`   Duration: ${dashboard.session.duration}`);
    }
    console.log(`   Project has status: ${dashboard.project.hasStatus}`);
    console.log('');

    // Test 2: Get session status
    console.log('Test 2: Get Session Status');
    const sessionStatus = await statusAPI.getSessionStatus();
    console.log('✅ Session status:', sessionStatus.active ? 'Active' : 'Inactive');
    console.log('');

    // Test 3: Get progress summary
    console.log('Test 3: Get Progress Summary');
    const progress = await statusAPI.getProgressSummary();
    if (progress.hasProgress) {
      console.log('✅ Progress summary:');
      console.log(`   Total phases: ${progress.summary.total}`);
      console.log(`   Completed: ${progress.summary.completed}`);
      console.log(`   In progress: ${progress.summary.inProgress}`);
      console.log(`   Percent complete: ${progress.summary.percentComplete}%`);
    } else {
      console.log('⚠️  No progress data available');
    }
    console.log('');

    // Test 4: Get task recommendations
    console.log('Test 4: Get Task Recommendations');
    const recommendations = await statusAPI.getTaskRecommendations();
    if (recommendations.recommendations.length > 0) {
      console.log('✅ Task recommendations:');
      if (recommendations.suggested) {
        console.log(`   Suggested: ${recommendations.suggested.task} (${recommendations.suggested.estimate})`);
      }
      console.log(`   Total options: ${recommendations.recommendations.length}`);
      console.log(`   Quick wins: ${recommendations.quickWins.length}`);
    } else {
      console.log('ℹ️  No task recommendations available');
    }
    console.log('');

    // Test 5: Check flow state
    console.log('Test 5: Check Flow State');
    const flowState = await statusAPI.checkFlowState();
    console.log('✅ Flow state checked:');
    console.log(`   In flow: ${flowState.inFlow}`);
    console.log(`   Reason: ${flowState.reason}`);
    if (flowState.duration) {
      console.log(`   Duration: ${flowState.duration}`);
    }
    console.log('');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

async function runTests() {
  console.log('═══════════════════════════════════════════════');
  console.log('  ZSH Workflow CLI - Status Tests');
  console.log('═══════════════════════════════════════════════\n');

  await testStatusAdapter();
  await testStatusAPI();

  console.log('═══════════════════════════════════════════════');
  console.log('✅ All status tests passed!');
  console.log('═══════════════════════════════════════════════\n');
}

// Run tests
runTests().catch(error => {
  console.error('❌ Test suite failed:', error);
  process.exit(1);
});
