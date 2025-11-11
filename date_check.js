// Date verification script
// Today: October 24, 2025
// Semester 1_2025_2026: startDate 1756659600000, endDate 1768669200000

const today = new Date('2025-10-24');
console.log('Today:', today.toISOString());
console.log('Today ms:', today.getTime());

const semesterStart = new Date(1756659600000);
console.log('\nSemester Start:', semesterStart.toISOString());
console.log('Semester Start:', semesterStart.toLocaleString('vi-VN'));

const semesterEnd = new Date(1768669200000);
console.log('\nSemester End:', semesterEnd.toISOString());
console.log('Semester End:', semesterEnd.toLocaleString('vi-VN'));

console.log('\nIs today within semester?', 
  today.getTime() >= semesterStart.getTime() && 
  today.getTime() <= semesterEnd.getTime()
);

// October 24, 2025 check
const oct24 = new Date('2025-10-24');
console.log('\nOctober 24, 2025:');
console.log('Day of week:', oct24.getDay()); // 0=Sunday, 6=Saturday
console.log('Day name:', ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][oct24.getDay()]);
