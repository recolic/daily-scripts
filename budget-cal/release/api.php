<?php

function newCost($date, $cost) {
    $file = 'costs.txt';
    $data = "$date,$cost\n";
    file_put_contents($file, $data, FILE_APPEND);
}

function newBudgetInfo($startDate, $budgetPerDay) {
    $file = 'budget_info.txt';
    $data = "$startDate,$budgetPerDay\n";
    file_put_contents($file, $data, FILE_APPEND);
}

function queryCurrentBudget($todayDate) {
    // Read and parse the file
    $filename = 'budget_info.txt';
    $lines = file($filename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $budgets = array_map('str_getcsv', $lines);

    // Sort the array by the date (first element of each sub-array)
    usort($budgets, function($a, $b) {  return strcmp($a[0], $b[0]);  });

    // Determine the active budget
    $activeBudget = "[N/A]";
    foreach ($budgets as $budget) {
        if ($todayDate >= $budget[0]) {
            $activeBudget = $budget[1];
        } else {
            break;
        }
    }

    return $activeBudget;
}

function renderPage() {
    $costsFile = 'costs.txt';
    $budgetFile = 'budget_info.txt';

    if (!file_exists($costsFile) || !file_exists($budgetFile)) {
        return [];
    }

    $costs = array_map('str_getcsv', file($costsFile));
    $budgets = array_map('str_getcsv', file($budgetFile));

    usort($costs, function($a, $b) {
        return strtotime($a[0]) - strtotime($b[0]);
    });

    usort($budgets, function($a, $b) {
        return strtotime($a[0]) - strtotime($b[0]);
    });

    $results = [];
    $budgetIndex = 0;
    $usedBudget = 0;
    $currentBudgetInfo = $budgets[$budgetIndex];
    $currentStartDate = $currentBudgetInfo[0];
    $currentBudgetPerDay = $currentBudgetInfo[1];
    if ($budgetIndex < count($budgets) - 1)
        $nextBudgetStartingDate = $budgets[$budgetIndex + 1][0];
    else
        $nextBudgetStartingDate = "2099-01-01";

    foreach ($costs as $cost) {
        $costDate = $cost[0];
        $costValue = $cost[1];

        // Check if cost is out of first budget ranges
        if ($budgetIndex >= count($budgets) || strtotime($costDate) < strtotime($currentStartDate)) {
            echo "Debug: Cost $costValue on $costDate is out of budget range. Did you forget to define budget?\n";
            continue;
        }

        // Move to the next budget range if the cost date is beyond the current range
        while (strtotime($costDate) >= strtotime($nextBudgetStartingDate)) {
            echo "DEBUG: summary: usedBud=$usedBudget, currBud/d=$currentBudgetPerDay, currentStartDate=$currentStartDate, nextStartDate=$nextBudgetStartingDate\n";
            $daysUsed = ceil($usedBudget / $currentBudgetPerDay);
            for ($i = 0; $i < $daysUsed; $i++) {
                $whichDayBudgetBeingUsed = strtotime("+$i days", strtotime($currentStartDate));
                if ($whichDayBudgetBeingUsed >= strtotime($nextBudgetStartingDate)) {
                    $uncoveredCost = $usedBudget - $currentBudgetPerDay * $i;
                    echo "Debug: Discarded $uncoveredCost at $nextBudgetStartingDate to start next budget range \n";
                    break;
                }
                $results[] = date('Y-m-d', $whichDayBudgetBeingUsed);
            }
            $usedBudget = 0;
            $budgetIndex++;
            $currentBudgetInfo = $budgets[$budgetIndex];
            $currentStartDate = $currentBudgetInfo[0];
            $currentBudgetPerDay = $currentBudgetInfo[1];
            if ($budgetIndex < count($budgets) - 1)
                $nextBudgetStartingDate = $budgets[$budgetIndex + 1][0];
            else
                $nextBudgetStartingDate = "2099-01-01";
        }

        // Add cost to the current budget
        $usedBudget += $costValue;
    }

    // Handle the remaining budget usage for the last budget range.
    echo "DEBUG:Tsummary: usedBud=$usedBudget, currBud/d=$currentBudgetPerDay, currentStartDate=$currentStartDate, nextStartDate=$nextBudgetStartingDate\n";
    $daysUsed = ceil($usedBudget / $currentBudgetPerDay);
    for ($i = 0; $i < $daysUsed; $i++) {
        $whichDayBudgetBeingUsed = strtotime("+$i days", strtotime($currentStartDate));
         if ($whichDayBudgetBeingUsed >= strtotime($nextBudgetStartingDate)) {
             $uncoveredCost = $usedBudget - $currentBudgetPerDay * $i;
             echo "Debug: Discarded $uncoveredCost at $nextBudgetStartingDate to start next budget range \n";
             break;
         }
         $results[] = date('Y-m-d', $whichDayBudgetBeingUsed);
    }

    return $results;
}

// function testRenderPage() {
//     // Clean up previous test data
// //    @unlink('costs.txt');
// //    @unlink('budget_info.txt');
// 
//     // Add some test data
// //    newBudgetInfo('2024-06-01', 30);
// //    newCost('2024-06-01', 50);
// //    newCost('2024-06-01', 75);
// //    newCost('2024-06-01', 30);
// //    newCost('2024-06-01', 40);
// //
// //    newBudgetInfo('2024-06-04', 100);
// //    newCost('2024-06-06', 30);
// //    newCost('2024-06-06', 40);
// //    newCost('2024-06-07', 140);
// 
//     // Get the result from renderPage
//     $result = renderPage();
// 
//     // Print the result
//     foreach ($result as $date) {
//         echo "Budget used on: $date\n";
//     }
// }
// 
// testRenderPage();

// Handling incoming requests
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['cost']) && isset($_POST['date'])) {
        // Handle new cost entry
        $cost = $_POST['cost'];
        $date = $_POST['date'];
        newCost($date, $cost);
        echo "New cost added: $cost on $date\n";
    } elseif (isset($_POST['daily_budget']) && isset($_POST['starting_date'])) {
        // Handle new budget info entry
        $dailyBudget = $_POST['daily_budget'];
        $startingDate = $_POST['starting_date'];
        newBudgetInfo($startingDate, $dailyBudget);
        echo "New budget info added: $dailyBudget per day starting from $startingDate\n";
    } elseif (isset($_POST['query_budget_for_date'])) {
        $date = $_POST['query_budget_for_date'];
        $res = queryCurrentBudget($date);
        echo "$res";
    } elseif (isset($_POST['query_spec_url'])) {
        $res = file_get_contents("spec_url.txt");
        if ($res === false) {die("read spec_url.txt failed");}
        else {echo "$res";}
    } else {
        echo "Invalid POST request\n";
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Handle render page request
    $results = renderPage();
    foreach ($results as $date) {
        echo "Budget used on: $date\n";
    }
} else {
    echo "Invalid request method\n";
}
?>
